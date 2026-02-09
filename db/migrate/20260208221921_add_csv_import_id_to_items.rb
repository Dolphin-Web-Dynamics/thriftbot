class AddCsvImportIdToItems < ActiveRecord::Migration[8.1]
  def change
    add_reference :items, :csv_import, null: true, foreign_key: true
  end
end
