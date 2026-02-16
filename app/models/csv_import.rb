class CsvImport < ApplicationRecord
  acts_as_tenant :user
  belongs_to :user

  has_many :items, dependent: :nullify

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  scope :recent, -> { order(created_at: :desc) }

  validates :filename, presence: true
  validates :user, presence: true
end
