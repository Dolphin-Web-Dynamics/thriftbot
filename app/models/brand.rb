class Brand < ApplicationRecord
  has_many :items, dependent: :nullify

  validates :name, presence: true, uniqueness: true

  def to_s
    name
  end
end
