class ScopeSkuUniquenessToUser < ActiveRecord::Migration[8.1]
  def change
    remove_index :items, :sku, unique: true
    add_index :items, [ :user_id, :sku ], unique: true
  end
end
