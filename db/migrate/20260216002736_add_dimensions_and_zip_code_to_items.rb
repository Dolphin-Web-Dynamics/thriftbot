class AddDimensionsAndZipCodeToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :length, :decimal, precision: 8, scale: 2
    add_column :items, :width, :decimal, precision: 8, scale: 2
    add_column :items, :height, :decimal, precision: 8, scale: 2
    add_column :items, :zip_code, :string
    add_index :items, :zip_code
  end
end
