class SubscriptionsController < ApplicationController
  skip_before_action :check_subscription

  def new
  end

  def create
    plan = params[:plan]
    price_id = stripe_price_id_for(plan)

    unless price_id
      redirect_to new_subscription_path, alert: "Invalid plan selected."
      return
    end

    customer = find_or_create_stripe_customer

    checkout_session = Stripe::Checkout::Session.create(
      customer: customer.id,
      payment_method_types: [ "card" ],
      line_items: [ { price: price_id, quantity: 1 } ],
      mode: "subscription",
      allow_promotion_codes: true,
      success_url: dashboard_url + "?subscription=success",
      cancel_url: new_subscription_url,
      metadata: { plan: plan }
    )

    redirect_to checkout_session.url, allow_other_host: true
  end

  def portal
    customer_id = current_user.stripe_customer_id
    unless customer_id
      redirect_to new_subscription_path, alert: "No subscription found."
      return
    end

    portal_session = Stripe::BillingPortal::Session.create(
      customer: customer_id,
      return_url: dashboard_url
    )

    redirect_to portal_session.url, allow_other_host: true
  end

  private

  def find_or_create_stripe_customer
    if current_user.stripe_customer_id.present?
      Stripe::Customer.retrieve(current_user.stripe_customer_id)
    else
      customer = Stripe::Customer.create(email: current_user.email_address)
      current_user.update!(stripe_customer_id: customer.id)
      customer
    end
  end

  def stripe_price_id_for(plan)
    case plan
    when "pro"
      Rails.application.credentials.dig(:stripe, :pro_price_id) || ENV["STRIPE_PRO_PRICE_ID"]
    when "business"
      Rails.application.credentials.dig(:stripe, :business_price_id) || ENV["STRIPE_BUSINESS_PRICE_ID"]
    end
  end
end
