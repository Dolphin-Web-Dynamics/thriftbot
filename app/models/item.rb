class Item < ApplicationRecord
  belongs_to :brand, optional: true
  belongs_to :category, optional: true
  belongs_to :subcategory, optional: true
  belongs_to :source, optional: true
  belongs_to :csv_import, optional: true

  has_many :listings, dependent: :destroy
  has_many :platforms, through: :listings
  has_one :sale, dependent: :destroy
  has_many :ai_generations, dependent: :destroy

  # Active Storage
  has_one_attached :front_image
  has_one_attached :back_image
  has_many_attached :measurement_images
  has_many_attached :tag_images
  has_many_attached :imperfection_images
  has_many_attached :additional_images

  # Enums
  enum :status, { drafted: 0, listed: 1, sold: 2, archived: 3, donated: 4 }
  enum :condition, {
    new_with_tags: 0,
    new_without_tags: 1,
    excellent: 2,
    good: 3,
    fair: 4
  }, prefix: true
  enum :target_gender, { mens: 0, womens: 1, unisex: 2 }, prefix: true

  # Validations
  validates :sku, presence: true, uniqueness: true

  # Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[sku general_title description brand_id category_id subcategory_id source_id
       status item_type product_type target_gender condition colors size tags]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[brand category subcategory source listings platforms]
  end

  # Scopes
  scope :in_stock, -> { where.not(status: [ :sold, :archived, :donated ]) }
  scope :by_brand, ->(brand) { where(brand: brand) }
  scope :by_source, ->(source) { where(source: source) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_save :track_status_change

  def profit
    return nil unless sale && acquisition_cost
    sale.revenue_received.to_d - acquisition_cost.to_d
  end

  def profit_margin
    return nil unless sale&.sold_price&.positive? && acquisition_cost
    (profit / sale.sold_price * 100).round(1)
  end

  def suggested_price_for(platform)
    return nil unless comp_price
    multiplier = case platform.pricing_tier
    when "lower"  then 0.85
    when "mid"    then 1.0
    when "higher" then 1.15
    else 1.0
    end
    (comp_price * multiplier).round(2)
  end

  private

  def track_status_change
    self.status_changed_at = Time.current if status_changed?
  end
end
