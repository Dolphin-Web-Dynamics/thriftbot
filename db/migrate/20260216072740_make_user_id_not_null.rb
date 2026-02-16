class MakeUserIdNotNull < ActiveRecord::Migration[8.1]
  def change
    change_column_null :items, :user_id, false
    change_column_null :csv_imports, :user_id, false
  end
end
