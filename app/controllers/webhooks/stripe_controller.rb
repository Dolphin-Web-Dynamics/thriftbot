module Webhooks
  class StripeController < ActionController::API
    def create
      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
      endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_signing_secret) || ENV["STRIPE_WEBHOOK_SIGNING_SECRET"]

      begin
        event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
      rescue JSON::ParserError
        head :bad_request and return
      rescue Stripe::SignatureVerificationError
        head :bad_request and return
      end

      case event.type
      when "checkout.session.completed"
        handle_checkout_completed(event.data.object)
      when "customer.subscription.updated"
        handle_subscription_updated(event.data.object)
      when "customer.subscription.deleted"
        handle_subscription_deleted(event.data.object)
      when "invoice.payment_failed"
        handle_payment_failed(event.data.object)
      end

      head :ok
    end

    private

    def handle_checkout_completed(session)
      user = User.find_by(stripe_customer_id: session.customer)
      return unless user

      plan = case session.metadata&.[]("plan")
      when "pro" then :pro_plan
      when "business" then :business_plan
      else :pro_plan
      end

      user.update!(
        stripe_subscription_id: session.subscription,
        subscription_status: :active,
        plan: plan
      )
    end

    def handle_subscription_updated(subscription)
      user = User.find_by(stripe_customer_id: subscription.customer)
      return unless user

      status = case subscription.status
      when "active" then :active
      when "past_due" then :past_due
      when "trialing" then :trialing
      when "canceled" then :canceled
      else :free
      end

      user.update!(
        stripe_subscription_id: subscription.id,
        subscription_status: status,
        subscription_ends_at: subscription.current_period_end ? Time.at(subscription.current_period_end) : nil
      )
    end

    def handle_subscription_deleted(subscription)
      user = User.find_by(stripe_customer_id: subscription.customer)
      return unless user

      user.update!(
        subscription_status: :canceled,
        subscription_ends_at: Time.current
      )
    end

    def handle_payment_failed(invoice)
      user = User.find_by(stripe_customer_id: invoice.customer)
      return unless user

      user.update!(subscription_status: :past_due)
    end
  end
end
