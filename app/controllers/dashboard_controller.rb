class DashboardController < ApplicationController
  def index
    @total_items = Item.in_stock.count
    @total_invested = Item.in_stock.sum(:acquisition_cost)
    @total_revenue = Sale.joins(:item).merge(Item.all).sum(:revenue_received)
    @total_sales_count = Sale.joins(:item).merge(Item.all).count
    @total_gross_profit = Sale.joins(:item).merge(Item.all).sum("sales.revenue_received - COALESCE(items.acquisition_cost, 0)")
    @items_listed = Item.listed.count
    @items_drafted = Item.drafted.count

    @recent_sales = Sale.joins(:item).merge(Item.all).includes(:item, :platform).order(sold_on: :desc).limit(10)
    @recent_items = Item.includes(:brand, :source).recent.limit(10)

    # Chart data
    @sales_by_platform = Sale.joins(:item, :platform).merge(Item.all).group("platforms.name").sum(:revenue_received)
    @sales_by_month = Sale.joins(:item).merge(Item.all).group_by_month(:sold_on, last: 12).sum(:revenue_received)
    @gross_profit_by_month = Sale.joins(:item).merge(Item.all)
      .group_by_month(:sold_on, last: 12)
      .sum("sales.revenue_received - COALESCE(items.acquisition_cost, 0)")
    @items_by_status = Item.group(:status).count
  end
end
