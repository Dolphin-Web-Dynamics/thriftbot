class AddUserToItemsAndCsvImports < ActiveRecord::Migration[8.1]
  def change
    add_reference :items, :user, null: true, foreign_key: true
    add_reference :csv_imports, :user, null: true, foreign_key: true
  end
end
