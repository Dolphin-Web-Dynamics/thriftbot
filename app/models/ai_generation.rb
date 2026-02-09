class AiGeneration < ApplicationRecord
  belongs_to :item

  validates :field_name, presence: true
  validates :result, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_field, ->(field) { where(field_name: field) }
end
