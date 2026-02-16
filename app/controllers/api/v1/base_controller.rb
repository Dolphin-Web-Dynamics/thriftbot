module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_token

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "not_found" }, status: :not_found
      end

      private

      def authenticate_token
        token = request.headers["Authorization"]&.delete_prefix("Bearer ")
        head :unauthorized unless token.present? && ActiveSupport::SecurityUtils.secure_compare(token, admin_password)
      end

      def admin_password
        ENV.fetch("ADMIN_PASSWORD")
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
