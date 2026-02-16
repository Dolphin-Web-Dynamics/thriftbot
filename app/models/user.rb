class User < ApplicationRecord
  has_secure_password
  has_secure_token :api_token

  has_many :items, dependent: :destroy
  has_many :csv_imports, dependent: :destroy
  has_many :listings, through: :items
  has_many :sales, through: :items

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true

  # Subscription
  enum :subscription_status, { trialing: 0, active: 1, past_due: 2, canceled: 3, free: 4 }

  # Plan tiers stored as string to allow flexibility
  enum :plan, { free_plan: "free", pro_plan: "pro", business_plan: "business" }, default: :free_plan

  FREE_TIER_ITEM_LIMIT = 25
  PRO_TIER_ITEM_LIMIT = 500

  PLANS = {
    free: { name: "Free", price: 0, item_limit: FREE_TIER_ITEM_LIMIT },
    pro: { name: "Pro", price: 9, item_limit: PRO_TIER_ITEM_LIMIT },
    business: { name: "Business", price: 19, item_limit: nil }
  }.freeze

  after_create :set_trial_period

  def subscribed?
    active? || trialing_and_valid? || free?
  end

  def trialing_and_valid?
    trialing? && trial_ends_at.present? && trial_ends_at > Time.current
  end

  def trial_expired?
    trialing? && trial_ends_at.present? && trial_ends_at <= Time.current
  end

  def item_limit
    case plan
    when "pro_plan" then PRO_TIER_ITEM_LIMIT
    when "business_plan" then nil
    else FREE_TIER_ITEM_LIMIT
    end
  end

  def can_create_items?
    return true if business_plan? && (active? || trialing_and_valid?)
    return true if (active? || trialing_and_valid?) && (item_limit.nil? || items.count < item_limit)
    items.count < FREE_TIER_ITEM_LIMIT
  end

  def item_limit_reached?
    !can_create_items?
  end

  def current_plan_name
    PLANS.dig(plan.delete_suffix("_plan").to_sym, :name) || "Free"
  end

  private

  def set_trial_period
    update(trial_ends_at: 14.days.from_now)
  end
end
