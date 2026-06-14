require "net/http"

class FinishReservationJob < ApplicationJob
  queue_as :default

  def perform(reservation_id)
    reservation = Reservation.find_by(id: reservation_id)
    return unless reservation
    return unless %w[confirmed active].include?(reservation.status)

    # Guard against race conditions: if the reservation was extended,
    # its end_time will be in the future and a new job will handle it.
    return if reservation.end_time > Time.current

    reservation.update!(status: :done)

    # Send logout (lock) command to the machine's warden
    machine = reservation.machine
    send_warden_logout(machine) if machine
  end

  private

  def send_warden_logout(machine)
    return if machine.warden_local_ip.blank? || machine.warden_callback_port.blank?

    uri = URI("http://#{machine.warden_local_ip}:#{machine.warden_callback_port}/reservation-ended")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["X-Warden-Secret"] = machine.warden_callback_secret if machine.warden_callback_secret.present?

    Net::HTTP.start(uri.hostname, uri.port, open_timeout: 5, read_timeout: 10) do |http|
      http.request(request)
    end
  rescue StandardError => e
    Rails.logger.error("FinishReservationJob: Failed to send logout to warden for machine #{machine.id}: #{e.message}")
  end
end
