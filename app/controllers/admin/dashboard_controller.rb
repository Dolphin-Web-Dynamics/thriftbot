module Admin
  class DashboardController < BaseController
    def index
      ActsAsTenant.without_tenant do
        @total_users = User.count
        @active_subscribers = User.where(subscription_status: [ :active, :free ]).count
        @trialing_users = User.where(subscription_status: :trialing).where("trial_ends_at > ?", Time.current).count
        @canceled_users = User.where(subscription_status: :canceled).count

        @users_by_plan = User.group(:plan).count
        @signups_by_month = User.group_by_month(:created_at, last: 12).count
        @cancellations_by_month = User.where(subscription_status: :canceled)
          .group_by_month(:updated_at, last: 12).count

        # Estimated MRR from plan counts
        plan_counts = @users_by_plan
        @estimated_mrr = (plan_counts.fetch("pro", 0) * 9) + (plan_counts.fetch("business", 0) * 19)

        @total_items = Item.count
        @total_sales = Sale.count
        @total_revenue = Sale.sum(:revenue_received)
      end
    end
  end
end
