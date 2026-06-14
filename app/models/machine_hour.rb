class MachineHour < ApplicationRecord
  extend Enumerize

  belongs_to :user

  enumerize :hours_type, in: [ :playhours ], default: :playhours
  enumerize :hours_status, in: [ :active, :expired, :reserved, :used ], default: :active

  before_create :set_start_amount
  after_save :update_status_based_on_hours

  private

  def update_status_based_on_hours
    # Auto-update status to :used if hours are depleted
    if hours_amount <= 0 && hours_status != :reserved
      update_column(:hours_status, :reserved)
    end
  end

  def set_start_amount
    self.start_amount = hours_amount if start_amount.zero?
  end
end
