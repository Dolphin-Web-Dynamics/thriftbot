class CreateListings < ActiveRecord::Migration[8.1]
  def change
    create_table :listings do |t|
      t.references :item, null: false, foreign_key: true
      t.references :platform, null: false, foreign_key: true
      t.decimal :asking_price, precision: 8, scale: 2, null: false
      t.integer :status, default: 0, null: false
      t.string :external_id
      t.string :external_url
      t.datetime :listed_at
      t.datetime :delisted_at
      t.text :platform_notes

      t.timestamps
    end

    add_index :listings, [ :item_id, :platform_id ], unique: true
  end
end
