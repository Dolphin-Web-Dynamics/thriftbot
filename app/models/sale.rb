class Sale < ApplicationRecord
  belongs_to :item
  belongs_to :platform
  belongs_to :listing, optional: true

  def self.ransackable_attributes(auth_object = nil)
    %w[sold_price revenue_received sold_on platform_id item_id]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[item platform]
  end

  validates :sold_price, presence: true, numericality: { greater_than: 0 }
  validates :sold_on, presence: true

  after_create :mark_item_sold
  after_create :delist_other_listings

  def profit
    return nil unless item.acquisition_cost
    revenue_received.to_d - item.acquisition_cost.to_d
  end

  def profit_margin
    return nil unless sold_price&.positive? && item.acquisition_cost
    (profit / sold_price * 100).round(1)
  end

  def net_revenue
    (revenue_received || sold_price).to_d - platform_fees.to_d - shipping_cost.to_d
  end

  private

  def mark_item_sold
    item.update!(status: :sold)
  end

  def delist_other_listings
    item.listings.active.where.not(platform: platform).find_each do |listing|
      listing.delist!
    end
    listing&.update!(status: :sold) if listing&.active?
  end
end
