class Platform < ApplicationRecord
  has_many :listings, dependent: :destroy
  has_many :items, through: :listings
  has_many :sales, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :pricing_tier, inclusion: { in: %w[lower mid higher], allow_blank: true }

  scope :active, -> { where(active: true) }

  def to_s
    name
  end
end
