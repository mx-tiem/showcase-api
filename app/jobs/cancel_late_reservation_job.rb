class CancelLateReservationJob < ApplicationJob
  queue_as :default

  def perform(reservation_id)
    reservation = Reservation.find_by(id: reservation_id)
    return unless reservation
    return unless reservation.status == "confirmed"

    # Guard against race conditions: if the reservation's late cancellation job
    # was rescheduled, this old job should not cancel it.
    tolerance = AppSetting.instance.start_late_tolerance
    expected_run_at = reservation.start_time + tolerance.minutes
    return if expected_run_at > Time.current

    reservation.update!(status: :cancelled)
  end
end
