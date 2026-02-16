class PagesController < ApplicationController
  skip_before_action :require_login
  skip_before_action :set_tenant
  skip_before_action :check_subscription

  layout "landing"

  def home
    redirect_to dashboard_path if current_user
  end
end
