class SalesController < ApplicationController
  def index
    @q = Sale.ransack(params[:q])
    @q.sorts = "sold_on desc" if @q.sorts.empty?
    @sales = @q.result.includes(:item, :platform, item: :brand)
    @pagy, @sales = pagy(@sales, limit: 25)

    @total_revenue = @sales.sum(:revenue_received)
    @total_profit = @sales.joins(:item).sum("sales.revenue_received - COALESCE(items.acquisition_cost, 0)")
  end

  def show
    @sale = Sale.includes(:item, :platform).find(params[:id])
  end
end
