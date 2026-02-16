require "test_helper"

class Webhooks::StripeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:stripe_user)
  end

  # --- Signature verification ---

  test "returns 400 for missing signature" do
    post webhooks_stripe_path, params: "{}", headers: { "CONTENT_TYPE" => "application/json" }
    assert_response :bad_request
  end

  test "returns 400 for invalid signature" do
    post webhooks_stripe_path,
      params: "{}",
      headers: {
        "CONTENT_TYPE" => "application/json",
        "HTTP_STRIPE_SIGNATURE" => "t=123,v1=badsig"
      }
    assert_response :bad_request
  end

  # --- checkout.session.completed ---

  test "checkout.session.completed activates user with pro plan" do
    event = stripe_event("checkout.session.completed", {
      "customer" => @user.stripe_customer_id,
      "subscription" => "sub_new_pro_123",
      "metadata" => { "plan" => "pro" }
    })

    post_webhook_with_event(event)
    assert_response :ok

    @user.reload
    assert @user.active?
    assert @user.pro_plan?
    assert_equal "sub_new_pro_123", @user.stripe_subscription_id
  end

  test "checkout.session.completed activates user with business plan" do
    event = stripe_event("checkout.session.completed", {
      "customer" => @user.stripe_customer_id,
      "subscription" => "sub_new_biz_123",
      "metadata" => { "plan" => "business" }
    })

    post_webhook_with_event(event)
    assert_response :ok

    @user.reload
    assert @user.active?
    assert @user.business_plan?
    assert_equal "sub_new_biz_123", @user.stripe_subscription_id
  end

  test "checkout.session.completed defaults to pro plan when plan metadata missing" do
    event = stripe_event("checkout.session.completed", {
      "customer" => @user.stripe_customer_id,
      "subscription" => "sub_default_123",
      "metadata" => {}
    })

    post_webhook_with_event(event)
    assert_response :ok

    @user.reload
    assert @user.pro_plan?
  end

  test "checkout.session.completed with unknown customer is a no-op" do
    event = stripe_event("checkout.session.completed", {
      "customer" => "cus_unknown_999",
      "subscription" => "sub_unknown",
      "metadata" => { "plan" => "pro" }
    })

    post_webhook_with_event(event)
    assert_response :ok
  end

  # --- customer.subscription.updated ---

  test "subscription.updated syncs active status" do
    event = stripe_event("customer.subscription.updated", {
      "id" => "sub_updated_123",
      "customer" => @user.stripe_customer_id,
      "status" => "active",
      "current_period_end" => 30.days.from_now.to_i
    })

    post_webhook_with_event(event)
    assert_response :ok

    @user.reload
    assert @user.active?
    assert_equal "sub_updated_123", @user.stripe_subscription_id
    assert_not_nil @user.subscription_ends_at
  end

  test "subscription.updated syncs past_due status" do
    event = stripe_event("customer.subscription.updated", {
      "id" => "sub_pastdue_123",
      "customer" => @user.stripe_customer_id,
      "status" => "past_due",
      "current_period_end" => 30.days.from_now.to_i
    })

    post_webhook_with_event(event)
    assert_response :ok

    @user.reload
    assert @user.past_due?
  end

  test "subscription.updated syncs trialing status" do
    event = stripe_event("customer.subscription.updated", {
      "id" => "sub_trial_123",
      "customer" => @user.stripe_customer_id,
      "status" => "trialing",
      "current_period_end" => 14.days.from_now.to_i
    })

    post_webhook_with_event(event)
    assert_response :ok

    @user.reload
    assert @user.trialing?
  end

  test "subscription.updated syncs canceled status" do
    event = stripe_event("customer.subscription.updated", {
      "id" => "sub_cancel_123",
      "customer" => @user.stripe_customer_id,
      "status" => "canceled",
      "current_period_end" => Time.current.to_i
    })

    post_webhook_with_event(event)
    assert_response :ok

    @user.reload
    assert @user.canceled?
  end

  test "subscription.updated maps unknown status to free" do
    event = stripe_event("customer.subscription.updated", {
      "id" => "sub_unknown_123",
      "customer" => @user.stripe_customer_id,
      "status" => "unpaid",
      "current_period_end" => nil
    })

    post_webhook_with_event(event)
    assert_response :ok

    @user.reload
    assert @user.free?
  end

  test "subscription.updated with unknown customer is a no-op" do
    event = stripe_event("customer.subscription.updated", {
      "id" => "sub_orphan_123",
      "customer" => "cus_nonexistent",
      "status" => "active",
      "current_period_end" => 30.days.from_now.to_i
    })

    post_webhook_with_event(event)
    assert_response :ok
  end

  # --- customer.subscription.deleted ---

  test "subscription.deleted sets canceled and subscription_ends_at" do
    event = stripe_event("customer.subscription.deleted", {
      "id" => @user.stripe_subscription_id,
      "customer" => @user.stripe_customer_id,
      "status" => "canceled"
    })

    post_webhook_with_event(event)
    assert_response :ok

    @user.reload
    assert @user.canceled?
    assert_not_nil @user.subscription_ends_at
    assert_in_delta Time.current, @user.subscription_ends_at, 5.seconds
  end

  # --- invoice.payment_failed ---

  test "payment_failed sets past_due" do
    event = stripe_event("invoice.payment_failed", {
      "customer" => @user.stripe_customer_id,
      "subscription" => @user.stripe_subscription_id
    })

    post_webhook_with_event(event)
    assert_response :ok

    @user.reload
    assert @user.past_due?
  end

  test "payment_failed with unknown customer is a no-op" do
    event = stripe_event("invoice.payment_failed", {
      "customer" => "cus_ghost",
      "subscription" => "sub_ghost"
    })

    post_webhook_with_event(event)
    assert_response :ok
  end

  # --- Unknown event type ---

  test "unknown event type returns 200 with no changes" do
    event = stripe_event("some.unknown.event", { "foo" => "bar" })

    post_webhook_with_event(event)
    assert_response :ok

    assert @user.reload.active?
  end

  private

  def stripe_event(type, data)
    Stripe::Event.construct_from({
      id: "evt_test_#{SecureRandom.hex(8)}",
      object: "event",
      type: type,
      data: { object: data }
    })
  end

  def post_webhook_with_event(event)
    original_method = Stripe::Webhook.method(:construct_event)
    Stripe::Webhook.define_singleton_method(:construct_event) { |*_args| event }

    post webhooks_stripe_path,
      params: "{}",
      headers: {
        "CONTENT_TYPE" => "application/json",
        "HTTP_STRIPE_SIGNATURE" => "t=#{Time.now.to_i},v1=fakesig"
      }
  ensure
    Stripe::Webhook.define_singleton_method(:construct_event, original_method)
  end
end
