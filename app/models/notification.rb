class Notification < ApplicationRecord
  belongs_to :user

  validates :title, presence: true
  validates :short_description, presence: true

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }
end
