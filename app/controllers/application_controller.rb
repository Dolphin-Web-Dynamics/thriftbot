class ApplicationController < ActionController::Base
  include Pagy::Method

  ADMIN_EMAIL = "anel@dolphinwebdynamics.com".freeze

  set_current_tenant_through_filter

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_login
  before_action :set_tenant
  before_action :check_subscription

  private

  def require_login
    redirect_to new_session_path, alert: "Please log in." unless current_user
  end

  def set_tenant
    set_current_tenant(current_user) if current_user
  end

  def check_subscription
    return unless current_user
    return if current_user.subscribed?
    return if subscription_exempt_controller?

    redirect_to new_subscription_path, alert: "Your trial has expired. Please subscribe to continue."
  end

  def subscription_exempt_controller?
    controller_name.in?(%w[sessions registrations subscriptions pages]) ||
      self.class.module_parent_name.in?(%w[Webhooks Admin])
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
  helper_method :current_user

  def admin_user?
    current_user&.email_address == ADMIN_EMAIL
  end
  helper_method :admin_user?
end
