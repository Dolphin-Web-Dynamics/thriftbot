require "application_system_test_case"

class SubscriptionFlowTest < ApplicationSystemTestCase
  setup do
    required = %w[STRIPE_SECRET_KEY STRIPE_PRO_PRICE_ID STRIPE_BUSINESS_PRICE_ID]
    missing = required.select { |key| ENV[key].blank? }
    if missing.any?
      skip "Skipping system test — missing #{missing.join(', ')}"
    end
    @user = users(:trialing_user)
  end

  test "pricing page renders with all plan tiers" do
    login_as_user @user
    visit new_subscription_path

    assert_text "Choose your plan"
    assert_text "Free"
    assert_text "$0"
    assert_text "Pro"
    assert_text "$9"
    assert_text "Business"
    assert_text "$19"
  end

  test "subscribe button redirects to Stripe Checkout" do
    login_as_user @user
    visit new_subscription_path

    click_button "Subscribe — $9/mo"

    # Should redirect to Stripe's hosted checkout
    assert_match %r{checkout\.stripe\.com}, current_url
  end

  test "expired trial user is redirected to subscription page" do
    expired_user = users(:expired_trial_user)
    login_as_user expired_user

    visit dashboard_path

    assert_current_path new_subscription_path
    assert_text "Your trial has expired"
  end

  test "active subscriber sees manage subscription button" do
    active_user = users(:stripe_user)
    login_as_user active_user
    visit new_subscription_path

    assert_text "Manage Subscription"
  end
end
