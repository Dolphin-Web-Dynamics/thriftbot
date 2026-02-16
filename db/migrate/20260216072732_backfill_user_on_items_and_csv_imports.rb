class BackfillUserOnItemsAndCsvImports < ActiveRecord::Migration[8.1]
  def up
    user_count = execute("SELECT COUNT(*) AS count FROM users").first["count"].to_i
    return if user_count == 0

    if user_count > 1
      raise ActiveRecord::IrreversibleMigration, "Multiple users exist; cannot safely backfill user_id — assign manually"
    end

    first_user_id = execute("SELECT id FROM users ORDER BY id LIMIT 1").first["id"]
    execute("UPDATE items SET user_id = #{first_user_id} WHERE user_id IS NULL")
    execute("UPDATE csv_imports SET user_id = #{first_user_id} WHERE user_id IS NULL")
  end

  def down
    execute("UPDATE items SET user_id = NULL")
    execute("UPDATE csv_imports SET user_id = NULL")
  end
end
