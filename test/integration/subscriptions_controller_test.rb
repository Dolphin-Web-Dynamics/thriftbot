require "test_helper"

class SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:trialing_user)
    @stripe_user = users(:stripe_user)
  end

  # --- GET /subscription/new ---

  test "renders pricing page" do
    login_as @user
    get new_subscription_path
    assert_response :success
    assert_select "h1", "Choose your plan"
  end

  test "requires authentication" do
    get new_subscription_path
    assert_redirected_to new_session_path
  end

  # --- POST /subscription ---

  test "create with invalid plan redirects with alert" do
    login_as @user

    post subscription_path, params: { plan: "invalid" }
    assert_redirected_to new_subscription_path
    assert_equal "Invalid plan selected.", flash[:alert]
  end

  test "create with pro plan creates checkout session and redirects" do
    login_as @user

    stub_request(:get, "https://api.stripe.com/v1/customers/cus_trialing_123")
      .to_return(status: 200, body: { id: "cus_trialing_123", object: "customer" }.to_json, headers: { "Content-Type" => "application/json" })

    stub_request(:post, "https://api.stripe.com/v1/checkout/sessions")
      .to_return(status: 200, body: {
        id: "cs_test_123",
        object: "checkout.session",
        url: "https://checkout.stripe.com/pay/cs_test_123"
      }.to_json, headers: { "Content-Type" => "application/json" })

    post subscription_path, params: { plan: "pro" }
    assert_response :redirect
    assert_match %r{checkout\.stripe\.com}, response.location
  end

  test "create with business plan creates checkout session" do
    login_as @user

    stub_request(:get, "https://api.stripe.com/v1/customers/cus_trialing_123")
      .to_return(status: 200, body: { id: "cus_trialing_123", object: "customer" }.to_json, headers: { "Content-Type" => "application/json" })

    stub_request(:post, "https://api.stripe.com/v1/checkout/sessions")
      .to_return(status: 200, body: {
        id: "cs_test_biz",
        object: "checkout.session",
        url: "https://checkout.stripe.com/pay/cs_test_biz"
      }.to_json, headers: { "Content-Type" => "application/json" })

    post subscription_path, params: { plan: "business" }
    assert_response :redirect
    assert_match %r{checkout\.stripe\.com}, response.location
  end

  test "create without stripe_customer_id creates new customer first" do
    user = users(:free_user)
    login_as user

    stub_request(:post, "https://api.stripe.com/v1/customers")
      .to_return(status: 200, body: {
        id: "cus_new_123",
        object: "customer",
        email: user.email_address
      }.to_json, headers: { "Content-Type" => "application/json" })

    stub_request(:post, "https://api.stripe.com/v1/checkout/sessions")
      .to_return(status: 200, body: {
        id: "cs_test_new",
        object: "checkout.session",
        url: "https://checkout.stripe.com/pay/cs_test_new"
      }.to_json, headers: { "Content-Type" => "application/json" })

    post subscription_path, params: { plan: "pro" }
    assert_response :redirect

    user.reload
    assert_equal "cus_new_123", user.stripe_customer_id
  end

  # --- POST /subscription/portal ---

  test "portal redirects to Stripe billing portal" do
    login_as @stripe_user

    stub_request(:post, "https://api.stripe.com/v1/billing_portal/sessions")
      .to_return(status: 200, body: {
        id: "bps_test_123",
        object: "billing_portal.session",
        url: "https://billing.stripe.com/session/bps_test_123"
      }.to_json, headers: { "Content-Type" => "application/json" })

    post portal_subscription_path
    assert_response :redirect
    assert_match %r{billing\.stripe\.com}, response.location
  end

  test "portal without stripe_customer_id redirects with alert" do
    user = users(:free_user)
    login_as user

    post portal_subscription_path
    assert_redirected_to new_subscription_path
    assert_equal "No subscription found.", flash[:alert]
  end
end
