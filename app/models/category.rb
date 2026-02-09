class Category < ApplicationRecord
  has_many :subcategories, dependent: :destroy
  has_many :items, dependent: :nullify

  validates :name, presence: true, uniqueness: true

  def to_s
    name
  end
end
