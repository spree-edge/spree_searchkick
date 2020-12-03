require 'spec_helper'

RSpec.describe Spree::Product, type: :model do
  describe 'searches' do
    let(:product) { create(:product) }

    it 'autocomplete by name' do
      keyword = product.name[0..6]
      Spree::Product.reindex
      expect(Spree::Product.autocomplete(keyword)).to eq([product.name.strip])
    end

    context 'products that are not yet available' do
      let(:product) { create(:product, available_on: nil) }

      it 'does not return them in autocomplete' do
        keyword = product.name[0..6]
        Spree::Product.reindex
        expect(Spree::Product.autocomplete(keyword)).to eq([])
      end
    end

    context 'products with no price' do
      let(:product) do
        create(:product).tap { |_| Spree::Price.update_all(amount: nil) }
      end

      it 'does not return them in autocomplete' do
        keyword = product.name[0..6]
        Spree::Product.reindex
        expect(Spree::Product.autocomplete(keyword)).to eq([])
      end
    end
  end

  describe '#search_data' do
    let!(:property) { create(:property, name: 'Length', filterable: true) }
    let!(:taxonomy) { create(:taxonomy, name: 'Categories') }
    let!(:taxon) { create(:taxon, name: 'T-shirts', taxonomy: taxonomy) }

    let(:product) do
      create(
        :product_in_stock,
        name: 'Some Product', 
        description: 'Example description',
        sku: 'SKU100',
        price: 350.90
      )
    end
    let(:data) do
      {
        id: product.id,
        name: 'Some Product',
        description: 'Example description',
        active: true,
        price: 350.90.to_d,
        currency: 'USD',
        in_stock: true,
        total_on_hand: 10,
        skus: ['SKU100'],
        slug: product.slug,
        created_at: product.created_at,
        updated_at: product.updated_at,
        property_ids: [property.id],
        property_names: ['Length'],
        taxon_ids: [taxonomy.root.id, taxon.id],
        taxon_names: ['Categories', 'T-shirts'],
        option_type_ids: [],
        option_type_names: [],
        option_value_ids: [],
        conversions: 0,
        length: '10in'
      }
    end

    before do
      product.set_property('Length', '10in')
      product.taxons << taxon
      product.reload
    end

    it 'contains all required data for ES' do
      expect(product.search_data.symbolize_keys).to eq data
    end
  end
end
