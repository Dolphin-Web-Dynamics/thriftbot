class CreateSales < ActiveRecord::Migration[8.1]
  def change
    create_table :sales do |t|
      t.references :item, null: false, foreign_key: true
      t.references :platform, null: false, foreign_key: true
      t.references :listing, foreign_key: true
      t.decimal :sold_price, precision: 8, scale: 2, null: false
      t.decimal :revenue_received, precision: 8, scale: 2
      t.decimal :platform_fees, precision: 8, scale: 2
      t.decimal :shipping_cost, precision: 8, scale: 2
      t.date :sold_on, null: false
      t.text :notes

      t.timestamps
    end

    add_index :sales, :sold_on
  end
end
