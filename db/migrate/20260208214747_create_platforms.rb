class CreatePlatforms < ActiveRecord::Migration[8.1]
  def change
    create_table :platforms do |t|
      t.string :name, null: false
      t.string :pricing_tier
      t.decimal :fee_percentage, precision: 5, scale: 2
      t.string :url_template
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :platforms, :name, unique: true
  end
end
