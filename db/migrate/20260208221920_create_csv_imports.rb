class CreateCsvImports < ActiveRecord::Migration[8.1]
  def change
    create_table :csv_imports do |t|
      t.string :filename, null: false
      t.integer :records_count, default: 0
      t.integer :status, default: 0, null: false
      t.text :error_log

      t.timestamps
    end
  end
end
