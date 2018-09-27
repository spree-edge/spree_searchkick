module Spree::ProductDecorator
  def self.prepended(base)
    base.searchkick word_start: [:name], settings: { number_of_replicas: 0 } unless base.respond_to?(:search_index)

    base.scope :search_import, lambda {
      includes(
        :orders,
        master: :default_price
      )
    }

    def base.autocomplete_fields
      [:name]
    end

    def base.search_fields
      [:name]
    end

    def base.autocomplete(keywords)
      if keywords
        Spree::Product.search(
          keywords,
          fields: autocomplete_fields,
          match: :word_start,
          limit: 10,
          load: false,
          misspellings: { below: 3 },
          where: search_where,
        ).map(&:name).map(&:strip).uniq
      else
        Spree::Product.search(
          "*",
          fields: autocomplete_fields,
          load: false,
          misspellings: { below: 3 },
          where: search_where,
        ).map(&:name).map(&:strip)
      end
    end

    def base.search_where
      {
        active: true,
        price: { not: nil },
      }
    end
  end

  def search_data
    json = {
      name: name,
      description: description,
      active: available?,
      created_at: created_at,
      updated_at: updated_at,
      price: price,
      currency: currency,
      conversions: orders.complete.count,
      taxon_ids: taxon_and_ancestors.map(&:id),
      taxon_names: taxon_and_ancestors.map(&:name),
    }

    loaded(:product_properties, :property).each do |prod_prop|
      json.merge!(Hash[prod_prop.property.name.downcase, prod_prop.value])
    end

    loaded(:taxons, :taxonomy).group_by(&:taxonomy).map do |taxonomy, taxons|
      json.merge!(Hash["#{taxonomy.name.downcase}_ids", taxon_by_taxonomy(taxonomy.id).map(&:id)])
    end

    json
  end

  def taxon_by_taxonomy(taxonomy_id)
    taxons.joins(:taxonomy).where(spree_taxonomies: { id: taxonomy_id })
  end

  def loaded(prop, incl)
    relation = send(prop)
    relation.loaded? ? relation : relation.includes(incl)
  end
end

Spree::Product.prepend(Spree::ProductDecorator)
