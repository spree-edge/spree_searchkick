module Spree
  module Search
    class Searchkick < Spree::Core::Search::Base
      attr_reader :params
      attr_accessor :show_in_stock

      def retrieve_products
        @products = base_elasticsearch
      end

      def retrieve_blogs
        Spree::BlogEntry.search(keyword_query, fields: [:title], match: :word_start)
      end

      def base_elasticsearch
        curr_page = page || 1
        Spree::Product.search(
          keyword_query,
          fields: Spree::Product.search_fields,
          where: where_query,
          aggs: attributes,
          smart_aggs: true,
          order: sorted,
          page: curr_page,
          per_page: per_page,
        )
      end

      def where_query
        where_query = {
          active: true,
          currency: current_currency,
          price: { not: nil },
          available: true
        }

        where_query[:colour_id] = colour_id if colour_id.present?
        where_query[:feature_ids] = feature_ids if feature_ids.present?
        where_query[:flowering_season_id] = flowering_season_id if flowering_season_id.present?
        where_query[:planting_position_id] = planting_position_id if planting_position_id.present?
        where_query[:pot_size_ids] = pot_size_ids if pot_size_ids.present?
        where_query[:soil_type_id] = soil_type_id if soil_type_id.present?
        where_query[:taxon_ids] = taxon_ids if taxon_ids.present?
        where_query[:month_ids] = month_ids if month_ids.present?
        where_query[:spread_id] = spread_id if spread_id.present?
        where_query[:height_id] = height_id if height_id.present?
        where_query[:in_stock_pot_size_ids] = in_stock_pot_size_ids if in_stock_pot_size_ids.present?

        where_query.merge!(products_in_stock) if show_in_stock
        add_search_filters(where_query)
      end

      def keyword_query
        keywords.nil? || keywords.empty? ? "*" : keywords
      end

      def sorted
        order_params = {}
        order_params[:conversions] = :desc if conversions
        order_params
      end

      def aggregations
        fs = []

        aggregation_classes.each do |agg_class|
          agg_class.filterable.each do |record|
            fs << record.filter_name.to_sym
          end
        end

        fs
      end

      def format_facets(aggs)
        formatted_facets = {}
        aggs.each do |field, aggregation|
          formatted_facets[field] = {}
          aggregation['buckets'].each do |bucket|
            formatted_facets[field][bucket['key'].to_s.to_sym] = bucket['doc_count']
          end
        end
        formatted_facets
      end

      def aggregation_classes
        [
          Spree::Taxonomy, 
          Spree::Property, 
          Spree::OptionType
        ]
      end

      def add_search_filters(query)
        return query unless search
        search.each do |name, scope_attribute|
          query.merge!(Hash[name, scope_attribute])
        end
        query
      end

      def prepare(params)
        super
        @properties[:conversions] = params[:conversions]
        @show_in_stock = params[:in_stock] == 'true'
        @params = params

        @properties[:colour_id] = params[:colour_id].present? ? params[:colour_id].map(&:to_i) : []
        @properties[:soil_type_id] = params[:soil_type_id].present? ? params[:soil_type_id].map(&:to_i) : []
        @properties[:planting_position_id] = params[:planting_position_id].present? ? params[:planting_position_id].map(&:to_i) : []
        @properties[:flowering_season_id] = params[:flowering_season_id].present? ? params[:flowering_season_id].map(&:to_i) : []
        @properties[:month_ids] = params[:month_id].present? ? params[:month_id].map(&:to_i) : []
        @properties[:feature_ids] = params[:feature_id].present? ? params[:feature_id].map(&:to_i) : []
        @properties[:height_id] = params[:height_id].present? ? params[:height_id].map(&:to_i) : []
        @properties[:spread_id] = params[:spread_id].present? ? params[:spread_id].map(&:to_i) : []
        @properties[:page] = params[:page]
        @properties[:per_page] = params[:per_page] || 12
        @properties[:taxon_ids] = if params[:taxon_id].present?
          params[:taxon_id].map(&:to_i).to_a
        else
          params[:taxon].present? ? [params[:taxon][:id]] : []
        end

        @properties[:pot_size_ids] = []
        @properties[:in_stock_pot_size_ids] = []

        if in_stock_by_pot_size?
          @properties[:in_stock_pot_size_ids] = params[:pot_size_ids].present? ? params[:pot_size_ids].map(&:to_i) : []
        else
          @properties[:pot_size_ids] = params[:pot_size_ids].present? ? params[:pot_size_ids].map(&:to_i) : []
        end

        @properties[:in_stock] = params[:in_stock].present? && params[:pot_size_ids].blank? ? [true] : []
        @properties[:order_by] = params[:sort_by].present? ? order_by_translator(params[:sort_by]) : 'name_sort ASC'
      end

      def in_stock_by_pot_size?
        params[:in_stock].present? && params[:pot_size_ids].present?
      end

      def order_by_translator(order_by)
        case order_by
        when 'price-low-to-high'
          { price: :asc }
        when 'price-high-to-low'
          { price: :desc }
        when 'newest-first'
          { available_on: :desc }
        when 'created_at'
          { created_at: :desc }
        else
          { name_sort: :asc }
        end
      end

      def attributes
        ['colour_id', 'feature_ids', 'flowering_season_id', 'height_id', 'month_ids', 'pot_size_ids', 'planting_position_id', 'soil_type_id', 'spread_id', 'taxon_ids'].map(&:to_sym)
      end

      def products_in_stock
        {
          in_stock: true,
          stock_available_state: true
        }
      end
    end
  end
end
