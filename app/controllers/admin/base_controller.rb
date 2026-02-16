module Admin
  class BaseController < ApplicationController
    before_action :require_admin
    skip_before_action :set_tenant
    skip_before_action :check_subscription

    layout "admin"

    private

    def require_admin
      unless admin_user?
        redirect_to dashboard_path, alert: "Not authorized."
      end
    end
  end
end
