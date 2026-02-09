class DashboardController < ApplicationController
  def index
    @total_items = Item.in_stock.count
    @total_invested = Item.in_stock.sum(:acquisition_cost)
    @total_revenue = Sale.sum(:revenue_received)
    @total_sales_count = Sale.count
    @items_listed = Item.listed.count
    @items_drafted = Item.drafted.count

    @recent_sales = Sale.includes(:item, :platform).order(sold_on: :desc).limit(10)
    @recent_items = Item.includes(:brand, :source).recent.limit(10)

    # Chart data
    @sales_by_platform = Sale.joins(:platform).group("platforms.name").sum(:revenue_received)
    @sales_by_month = Sale.group_by_month(:sold_on, last: 12).sum(:revenue_received)
    @items_by_status = Item.group(:status).count
  end
end
