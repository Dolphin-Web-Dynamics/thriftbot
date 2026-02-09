class Subcategory < ApplicationRecord
  belongs_to :category
  has_many :items, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :category_id }

  def to_s
    name
  end
end
