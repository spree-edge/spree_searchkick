class AddFiltersToFilterable < ActiveRecord::Migration[6.0]
  def change
    add_index :spree_taxonomies, :filterable
    add_index :spree_properties, :filterable
    add_index :spree_option_types, :filterable
  end
end
