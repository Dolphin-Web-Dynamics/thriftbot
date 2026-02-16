class AddSubscriptionFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :stripe_customer_id, :string
    add_column :users, :stripe_subscription_id, :string
    add_column :users, :subscription_status, :integer, default: 0
    add_column :users, :trial_ends_at, :datetime
    add_column :users, :subscription_ends_at, :datetime

    add_index :users, :stripe_customer_id, unique: true
    add_index :users, :stripe_subscription_id, unique: true
  end
end
