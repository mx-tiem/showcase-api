class Reservation < ApplicationRecord
  extend Enumerize
  belongs_to :user
  belongs_to :machine
  belongs_to :creator, class_name: "User"

  validates :start_time, presence: true
  validates :end_time, presence: true

  enumerize :status, in: [ :new, :confirmed, :active, :done, :cancelled ], default: :new

  scope :current_and_future, ->(user) { user.reservations.where("status = ? OR status = ? OR status = ?", "confirmed", "active", "new") }

  def duration_in_hours
    return 0 unless start_time && end_time
    ((end_time - start_time) / 1.hour).round(2)
  end
end
