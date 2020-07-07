class AddFilterableToSpreeOptionTypes < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_option_types, :filterable, :boolean
  end
end
