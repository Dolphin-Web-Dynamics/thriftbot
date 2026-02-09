class SalesController < ApplicationController
  before_action :set_sale, only: [ :show, :edit, :update ]

  def index
    @q = Sale.ransack(params[:q])
    @q.sorts = "sold_on desc" if @q.sorts.empty?
    @sales = @q.result.includes(:item, :platform, item: :brand)
    @pagy, @sales = pagy(@sales, limit: 25)

    @total_revenue = @sales.sum(:revenue_received)
    @total_profit = @sales.joins(:item).sum("sales.revenue_received - COALESCE(items.acquisition_cost, 0)")
  end

  def show
  end

  def edit
  end

  def update
    if @sale.update(sale_params)
      redirect_to item_path(@sale.item), notice: "Sale updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_sale
    @sale = Sale.includes(:item, :platform).find(params[:id])
  end

  def sale_params
    params.require(:sale).permit(
      :platform_id, :sold_price, :revenue_received,
      :platform_fees, :shipping_cost, :sold_on, :notes
    )
  end
end
