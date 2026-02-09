class CsvImport < ApplicationRecord
  has_many :items, dependent: :nullify

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  scope :recent, -> { order(created_at: :desc) }

  validates :filename, presence: true
end
