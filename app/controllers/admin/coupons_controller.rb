module Admin
  class CouponsController < BaseController
    def index
      @coupons = Stripe::Coupon.list(limit: 100).data
      @promotion_codes = Stripe::PromotionCode.list(limit: 100).data
    rescue Stripe::StripeError => e
      @coupons = []
      @promotion_codes = []
      flash.now[:alert] = "Could not load coupons: #{e.message}"
    end

    def new
    end

    def create
      coupon_params = {
        name: params[:name],
        duration: params[:duration]
      }

      if params[:discount_type] == "percent"
        coupon_params[:percent_off] = params[:percent_off].to_f
      else
        coupon_params[:amount_off] = (params[:amount_off].to_f * 100).to_i
        coupon_params[:currency] = "usd"
      end

      coupon_params[:duration_in_months] = params[:duration_in_months].to_i if params[:duration] == "repeating"

      coupon = Stripe::Coupon.create(coupon_params)

      if params[:promo_code].present?
        begin
          Stripe::PromotionCode.create(
            coupon: coupon.id,
            code: params[:promo_code]
          )
        rescue Stripe::StripeError => e
          redirect_to admin_coupons_path, alert: "Coupon created, but promo code failed: #{e.message}"
          return
        end
      end

      redirect_to admin_coupons_path, notice: "Coupon created."
    rescue Stripe::StripeError => e
      flash.now[:alert] = "Error: #{e.message}"
      render :new, status: :unprocessable_entity
    end
  end
end
