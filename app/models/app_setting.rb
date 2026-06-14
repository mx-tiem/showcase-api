class AppSetting < ApplicationRecord
  VALID_DAYS = %w[monday tuesday wednesday thursday friday saturday sunday].freeze

  validates :opening_hours, presence: true
  validates :closing_hours, presence: true
  validates :working_days, presence: true
  validates :free_cancellation_hours, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :min_hours_before_reservation, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :max_play_discount, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :max_play_discount_hours_required, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :start_late_tolerance, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :valid_working_days
  validate :closing_after_opening

  def self.instance
    first_or_create!(
      opening_hours: "14:00",
      closing_hours: "22:00",
      working_days: VALID_DAYS,
      free_cancellation_hours: 4,
      min_hours_before_reservation: 2,
      max_play_discount: 10,
      max_play_discount_hours_required: 100,
      start_late_tolerance: 15
    )
  end

  def self.reset_to_defaults!
    instance.update!(
      opening_hours: "14:00",
      closing_hours: "22:00",
      working_days: VALID_DAYS,
      free_cancellation_hours: 4,
      min_hours_before_reservation: 2,
      max_play_discount: 10,
      max_play_discount_hours_required: 100,
      start_late_tolerance: 15
    )
  end

  private

  def valid_working_days
    return if working_days.blank?

    invalid = working_days - VALID_DAYS
    errors.add(:working_days, "contains invalid days: #{invalid.join(', ')}") if invalid.any?
  end

  def closing_after_opening
    return if opening_hours.blank? || closing_hours.blank?

    errors.add(:closing_hours, "must be after opening hours") if closing_hours <= opening_hours
  end
end
