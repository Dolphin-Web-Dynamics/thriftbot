class Listing < ApplicationRecord
  belongs_to :item
  belongs_to :platform
  has_one :sale, dependent: :nullify

  enum :status, { draft: 0, active: 1, paused: 2, sold: 3, delisted: 4 }

  validates :asking_price, presence: true, numericality: { greater_than: 0 }
  validates :item_id, uniqueness: { scope: :platform_id, message: "already has a listing on this platform" }

  scope :active_listings, -> { where(status: :active) }

  def mark_listed!
    update!(status: :active, listed_at: Time.current)
  end

  def delist!
    update!(status: :delisted, delisted_at: Time.current)
  end
end
