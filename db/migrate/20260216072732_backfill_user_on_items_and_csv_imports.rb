class BackfillUserOnItemsAndCsvImports < ActiveRecord::Migration[8.1]
  def up
    first_user_id = execute("SELECT id FROM users ORDER BY id LIMIT 1").first&.fetch("id")
    return unless first_user_id

    execute("UPDATE items SET user_id = #{first_user_id} WHERE user_id IS NULL")
    execute("UPDATE csv_imports SET user_id = #{first_user_id} WHERE user_id IS NULL")
  end

  def down
    execute("UPDATE items SET user_id = NULL")
    execute("UPDATE csv_imports SET user_id = NULL")
  end
end
