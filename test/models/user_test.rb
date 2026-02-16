require "test_helper"

class UserTest < ActiveSupport::TestCase
  # --- subscribed? ---

  test "subscribed? returns true for active user" do
    user = users(:admin)
    assert user.subscribed?
  end

  test "subscribed? returns true for trialing user with valid trial" do
    user = users(:trialing_user)
    assert user.subscribed?
  end

  test "subscribed? returns false for trialing user with expired trial" do
    user = users(:expired_trial_user)
    assert_not user.subscribed?
  end

  test "subscribed? returns true for free user" do
    user = users(:free_user)
    assert user.subscribed?
  end

  test "subscribed? returns false for canceled user" do
    user = users(:canceled_user)
    assert_not user.subscribed?
  end

  test "subscribed? returns false for past_due user" do
    user = users(:past_due_user)
    assert_not user.subscribed?
  end

  # --- trialing_and_valid? ---

  test "trialing_and_valid? returns true when trial is in the future" do
    user = users(:trialing_user)
    assert user.trialing_and_valid?
  end

  test "trialing_and_valid? returns false when trial has expired" do
    user = users(:expired_trial_user)
    assert_not user.trialing_and_valid?
  end

  test "trialing_and_valid? returns false when trial_ends_at is nil" do
    user = users(:trialing_user)
    user.trial_ends_at = nil
    assert_not user.trialing_and_valid?
  end

  test "trialing_and_valid? returns false for non-trialing status" do
    user = users(:admin) # active status
    assert_not user.trialing_and_valid?
  end

  # --- trial_expired? ---

  test "trial_expired? returns true when trial is in the past" do
    user = users(:expired_trial_user)
    assert user.trial_expired?
  end

  test "trial_expired? returns false when trial is valid" do
    user = users(:trialing_user)
    assert_not user.trial_expired?
  end

  test "trial_expired? returns false for non-trialing user" do
    user = users(:admin)
    assert_not user.trial_expired?
  end

  # --- item_limit ---

  test "item_limit returns 25 for free plan" do
    user = users(:free_user)
    assert_equal User::FREE_TIER_ITEM_LIMIT, user.item_limit
  end

  test "item_limit returns 500 for pro plan" do
    user = users(:stripe_user)
    assert_equal User::PRO_TIER_ITEM_LIMIT, user.item_limit
  end

  test "item_limit returns nil for business plan" do
    user = users(:business_user)
    assert_nil user.item_limit
  end

  # --- can_create_items? / item_limit_reached? ---

  test "can_create_items? returns true for business plan active user" do
    user = users(:business_user)
    assert user.can_create_items?
    assert_not user.item_limit_reached?
  end

  test "can_create_items? returns true for active pro user under limit" do
    user = users(:stripe_user)
    assert user.can_create_items?
  end

  test "can_create_items? returns true for free user under limit" do
    user = users(:free_user)
    assert user.can_create_items?
  end

  # --- enum values ---

  test "subscription_status enum has correct values" do
    assert_equal({ "trialing" => 0, "active" => 1, "past_due" => 2, "canceled" => 3, "free" => 4 }, User.subscription_statuses)
  end

  test "plan enum has correct values" do
    assert_equal({ "free_plan" => "free", "pro_plan" => "pro", "business_plan" => "business" }, User.plans)
  end

  # --- set_trial_period callback ---

  test "set_trial_period sets trial_ends_at on create" do
    user = User.create!(
      email_address: "newuser@test.com",
      password: "password",
      password_confirmation: "password"
    )
    assert_not_nil user.trial_ends_at
    assert_in_delta 14.days.from_now, user.trial_ends_at, 5.seconds
  end

  # --- PLANS constant ---

  test "PLANS constant has correct structure" do
    assert_equal 3, User::PLANS.size
    assert_equal "Free", User::PLANS[:free][:name]
    assert_equal 9, User::PLANS[:pro][:price]
    assert_nil User::PLANS[:business][:item_limit]
  end

  # --- current_plan_name ---

  test "current_plan_name returns correct name for each plan" do
    assert_equal "Pro", users(:stripe_user).current_plan_name
    assert_equal "Business", users(:business_user).current_plan_name
    assert_equal "Free", users(:free_user).current_plan_name
  end
end
