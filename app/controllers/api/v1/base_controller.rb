module Api
  module V1
    class BaseController < ActionController::API
      include ActsAsTenant::ControllerExtensions

      set_current_tenant_through_filter

      before_action :authenticate_token
      before_action :set_tenant

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "not_found" }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def authenticate_token
        token = request.headers["Authorization"]&.delete_prefix("Bearer ")
        return head(:unauthorized) unless token.present?

        @current_api_user = User.find_by(api_token: token)
        head(:unauthorized) unless @current_api_user
      end

      def set_tenant
        set_current_tenant(@current_api_user)
      end

      def default_url_options
        if Rails.env.production?
          { host: "thriftbot.smelltherosessecondhand.com", protocol: "https" }
        else
          { host: "localhost", port: 3000 }
        end
      end
    end
  end
end
