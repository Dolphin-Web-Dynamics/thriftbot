module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_token

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "not_found" }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def authenticate_token
        token = request.headers["Authorization"]&.delete_prefix("Bearer ")
        expected = api_token
        head :unauthorized and return unless token.present? && expected.present?
        head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(token, expected)
      end

      def api_token
        ENV.fetch("API_BEARER_TOKEN") { ENV.fetch("ADMIN_PASSWORD", nil) }
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
