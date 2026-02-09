class CreateSources < ActiveRecord::Migration[8.1]
  def change
    create_table :sources do |t|
      t.string :name, null: false
      t.string :source_type

      t.timestamps
    end

    add_index :sources, :name, unique: true
  end
end
