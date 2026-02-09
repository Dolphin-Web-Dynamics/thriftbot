class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.string :sku, null: false
      t.string :general_title
      t.string :shopify_title
      t.text :description
      t.text :chatgpt_description
      t.text :unified_description
      t.references :brand, foreign_key: true
      t.references :category, foreign_key: true
      t.references :subcategory, foreign_key: true
      t.string :size
      t.string :product_model
      t.string :colors
      t.string :materials
      t.string :body_fit
      t.string :fit
      t.string :item_type
      t.string :product_type
      t.integer :condition, default: 0
      t.string :occasion
      t.integer :target_gender
      t.decimal :weight, precision: 8, scale: 2
      t.text :imperfections
      t.text :notes
      t.references :source, foreign_key: true
      t.decimal :acquisition_cost, precision: 8, scale: 2
      t.date :acquired_on
      t.decimal :comp_price, precision: 8, scale: 2
      t.string :comp_url
      t.decimal :retail_price, precision: 8, scale: 2
      t.string :retail_url
      t.integer :status, default: 0, null: false
      t.datetime :status_changed_at
      t.boolean :listed_with_vendoo, default: false, null: false
      t.string :canva_url
      t.string :picture_label_url
      t.string :image_url
      t.string :tags

      t.timestamps
    end

    add_index :items, :sku, unique: true
    add_index :items, :status
    add_index :items, :item_type
  end
end
