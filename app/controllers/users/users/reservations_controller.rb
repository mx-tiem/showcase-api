require "net/http"

class Users::Users::ReservationsController < ApplicationController
  include Pagy::Method

  def index
    collection = current_user.reservations.includes(:machine, :user, :creator)
    # Default sort for my_reservations: start_time DESC (most recent first)
    collection = collection.order(start_time: :desc) unless sorting_params[:sort_by].present?
    collection = apply_sorting(collection)

    pagy, reservations = pagy(:offset, collection, limit: pagination_params[:per_page] || 10)
    render json: {
      reservations: serialize_reservations(reservations),
      pagy: pagy_metadata(pagy)
    }
  end

  def cancel_reservation
    reservation = current_user.reservations.find_by(id: reservation_params[:reservation_id])

    unless reservation
      return render json: { error: "Reservation not found" }, status: :not_found
    end

    unless %w[confirmed active].include?(reservation.status)
      return render json: { error: "Only confirmed or active reservations can be cancelled" }, status: :unprocessable_entity
    end

    app_setting = AppSetting.instance
    hours_until_start = (reservation.start_time - Time.current) / 1.hour
    is_active = reservation.status == "active"

    # Refund if not active and cancelled within the free cancellation window
    eligible_for_refund = !is_active && hours_until_start >= app_setting.free_cancellation_hours
    refunded_hours = 0

    ActiveRecord::Base.transaction do
      reservation.update!(status: :cancelled)
      cancel_late_cancellation_job(reservation)
      cancel_finish_job(reservation)

      if eligible_for_refund
        refunded_hours = refund_hours_to_creator(reservation)
      end
    end

    render json: {
      message: "Reservation cancelled successfully",
      refunded_hours: refunded_hours,
      reservation: serialize_reservation(reservation.reload)
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "Failed to cancel reservation: #{e.message}" }, status: :unprocessable_entity
  end

  def active
    reservations = current_user.reservations
      .includes(:machine, :user, :creator)
      .where(status: %w[confirmed active])
      .order(Arel.sql("CASE WHEN status = 'active' THEN 0 ELSE 1 END, start_time DESC"))

    render json: {
      reservations: serialize_reservations(reservations)
    }
  end

  def create
    reservation_data = create_reservation_params
    parsed_start_time = parse_datetime(reservation_data[:start_datetime])
    parsed_end_time = parse_datetime(reservation_data[:end_datetime])
    duration_in_hours = calculate_duration_in_hours(parsed_start_time, parsed_end_time)

    users_machines = reservation_data[:usersMachines] || {}

    user_ids = users_machines.keys.map(&:to_i)
    machine_ids = users_machines.values.uniq

    users = User.where(id: user_ids).includes(:machine_hours)
    machines = Machine.where(id: machine_ids, status: [ :available, :working ])

    # Create reservations for each user
    created_reservations = []
    errors = []

    users_machines.each do |user_id_str, machine_id|
      user_id = user_id_str.to_i
      user = users.find { |u| u.id == user_id }
      next unless user

      machine = machines.find { |m| m.id == machine_id }
      next unless machine

      # All reservations created by the user are confirmed
      status = :confirmed

      # Validate playhours for current user
      if current_user.available_playhours < duration_in_hours
        errors << { user_id: user_id, errors: [ "Insufficient playhours. Required: #{duration_in_hours}, Available: #{current_user.available_playhours}" ] }
        next
      end

      # Validate for overlapping confirmed reservations for the target user
      if has_overlapping_confirmed_reservation?(user, parsed_start_time, parsed_end_time)
        errors << { user_id: user_id, errors: [ "User #{user.name} has an overlapping confirmed reservation" ] }
        next
      end

      reservation = Reservation.new(
        user_id: user_id,
        machine_id: machine.id,
        start_time: parsed_start_time,
        end_time: parsed_end_time,
        status: status,
        creator_id: current_user.id
      )

      if reservation.save
        # Deduct hours from current user's machine_hours
        deduct_result = deduct_hours_from_machine_hours(current_user, duration_in_hours, reservation)
        if deduct_result[:success]
          created_reservations << reservation
          machine.rotate_priority!
          schedule_late_cancellation(reservation)
          schedule_finish(reservation)

          # Notify the user if someone else created the reservation for them
          if reservation.user_id != current_user.id
            Notification.create!(
              user_id: reservation.user_id,
              title: "Reservation Created",
              short_description: "#{current_user.name} booked a session for you on #{reservation.start_time.strftime('%b %d at %H:%M')}.",
              long_description: "#{current_user.name} created a reservation for you on machine #{machine.name} from #{reservation.start_time.strftime('%b %d %H:%M')} to #{reservation.end_time.strftime('%H:%M')}.",
              icon: "event"
            )
          end
        else
          errors << { user_id: user_id, machine_id: machine.id, errors: [ deduct_result[:error] ] }
          reservation.destroy # Rollback
        end
      else
        errors << { user_id: user_id, machine_id: machine.id, errors: reservation.errors.full_messages }
      end
    end

    render_reservation_creation_response(created_reservations, errors)
  end

  def max_extend
    reservation = current_user.reservations.find_by(id: params[:id])

    unless reservation
      return render json: { error: "Reservation not found" }, status: :not_found
    end

    unless reservation.status == "active"
      return render json: { error: "Only active reservations can be extended" }, status: :unprocessable_entity
    end

    max_hours = calculate_max_extend_hours(reservation)

    render json: {
      reservation_id: reservation.id,
      current_end_time: reservation.end_time.iso8601,
      max_extend_hours: max_hours,
      available_playhours: current_user.available_playhours
    }
  end

  def extend
    reservation = current_user.reservations.find_by(id: extend_params[:reservation_id])

    unless reservation
      return render json: { error: "Reservation not found" }, status: :not_found
    end

    unless reservation.status == "active"
      return render json: { error: "Only active reservations can be extended" }, status: :unprocessable_entity
    end

    extend_hours = extend_params[:extend_hours].to_f
    if extend_hours <= 0
      return render json: { error: "Extend hours must be positive" }, status: :unprocessable_entity
    end

    max_hours = calculate_max_extend_hours(reservation)
    if extend_hours > max_hours
      return render json: { error: "Cannot extend by #{extend_hours}h. Maximum is #{max_hours}h" }, status: :unprocessable_entity
    end

    new_end_time = reservation.end_time + extend_hours.hours

    ActiveRecord::Base.transaction do
      reservation.update!(end_time: new_end_time)

      deduct_result = deduct_hours_from_machine_hours(current_user, extend_hours, reservation)
      unless deduct_result[:success]
        raise ActiveRecord::Rollback, deduct_result[:error]
      end
    end

    # Check if the transaction was rolled back
    if reservation.reload.end_time == new_end_time
      # Reschedule the finish job for the new end time
      cancel_finish_job(reservation)
      schedule_finish(reservation)

      # Notify warden about the extension
      notify_warden_session_extended(reservation.machine, new_end_time)

      render json: {
        message: "Reservation extended successfully",
        reservation: serialize_reservation(reservation)
      }
    else
      render json: { error: "Failed to extend reservation: insufficient playhours" }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "Failed to extend reservation: #{e.message}" }, status: :unprocessable_entity
  end

  def check_availability
    app_setting = AppSetting.instance
    app_opening_hour = app_setting.opening_hours.hour
    app_closing_hour = app_setting.closing_hours.hour
    min_hours_before = app_setting.min_hours_before_reservation
    app_working_days = app_setting.working_days
    now = Time.current

    user_ids = reservation_params[:user_ids] || []
    start_datetime = parse_datetime(reservation_params[:start_time])
    duration = reservation_params[:duration].to_f

    users_data = user_ids.any? ? User.where(id: user_ids).select(:id, :name).map { |u| { id: u.id, name: u.name } } : []

    base_date = start_datetime.to_date
    requested_minute = start_datetime.min
    dates = build_date_range(base_date)

    # Get all available machines
    available_machines = Machine.where(status: [ :available, :working ])

    results = []

    dates.each do |date|
      # Skip dates not covered by AppSetting working days
      day_name = date.strftime("%A").downcase
      next unless app_working_days.include?(day_name)

      # Get blocking reservations only for current user
      blocking_reservations = get_blocking_reservations_for_current_user(date)

      # Group reservations by machine
      reservations_by_machine = blocking_reservations.group_by(&:machine_id)

      # Find available slots per machine
      machines_by_slot = {}

      available_machines.each do |machine|
        # Skip if this machine doesn't operate on this weekday
        next unless machine.working_days.include?(day_name)

        start_work_hour = machine.start_work_hours.hour
        # If end hour is less than or equal to start hour, machine works past midnight
        end_work_hour = machine.end_work_hours.hour
        end_work_hour = 0 if end_work_hour <= start_work_hour
        end_work_hour = 0 if machine.end_work_hours.hour == 23 && machine.end_work_hours.min >= 59
        machine_reservations = reservations_by_machine[machine.id] || []

        # Find available slots for this machine
        available_slots = find_available_slots(
          date,
          start_work_hour,
          end_work_hour,
          machine_reservations,
          duration,
          requested_minute,
          app_opening_hour,
          app_closing_hour,
          min_hours_before,
          now
        )

        # Add this machine to each available slot
        available_slots.each do |slot_time|
          machines_by_slot[slot_time] ||= []
          machines_by_slot[slot_time] << {
            machine_id: machine.id,
            machine_name: machine.name,
            reservation_priority: machine.reservation_priority
          }
        end
      end

      # Format results for this date
      if machines_by_slot.any?
        num_machines_needed = user_ids.any? ? user_ids.length : nil

        available_reservations = machines_by_slot.filter_map do |slot_time, machines|
          # Skip this slot if there aren't enough machines for all users
          next if num_machines_needed && machines.length < num_machines_needed

          # Sort by priority (lower number = higher priority), then take limited number
          sorted_machines = machines.sort_by { |m| m[:reservation_priority] || Float::INFINITY }
          limited_machines = num_machines_needed ? sorted_machines.take(num_machines_needed) : sorted_machines

          # slot_time is already a Time object
          end_time = slot_time + (duration * 3600)

          {
            start_time: slot_time.strftime("%Y-%m-%dT%H:%M:%S"),
            end_time: end_time.strftime("%Y-%m-%dT%H:%M:%S"),
            machines: limited_machines
          }
        end.sort_by { |slot| slot[:start_time] }

        results << {
          date: date,
          original_date: date == base_date,
          users: users_data,
          duration: duration,
          min_start_hour: machines_by_slot.keys.min.strftime("%Y-%m-%dT%H:%M:%S"),
          max_start_hour: machines_by_slot.keys.max.strftime("%Y-%m-%dT%H:%M:%S"),
          available_reservations: available_reservations
        }
      end
    end

    render json: results
  end

  private

  def schedule_late_cancellation(reservation)
    tolerance = AppSetting.instance.start_late_tolerance
    run_at = reservation.start_time + tolerance.minutes
    job = CancelLateReservationJob.set(wait_until: run_at).perform_later(reservation.id)
    reservation.update_column(:late_cancellation_job_id, job.provider_job_id)
  end

  def cancel_late_cancellation_job(reservation)
    return unless reservation.late_cancellation_job_id.present?

    SolidQueue::Job.find_by(id: reservation.late_cancellation_job_id)&.destroy
    reservation.update_column(:late_cancellation_job_id, nil)
  end

  def schedule_finish(reservation)
    job = FinishReservationJob.set(wait_until: reservation.end_time).perform_later(reservation.id)
    reservation.update_column(:finish_job_id, job.provider_job_id)
  end

  def cancel_finish_job(reservation)
    return unless reservation.finish_job_id.present?

    SolidQueue::Job.find_by(id: reservation.finish_job_id)&.destroy
    reservation.update_column(:finish_job_id, nil)
  end

  def notify_warden_session_extended(machine, new_end_time)
    return unless machine
    return if machine.warden_local_ip.blank? || machine.warden_callback_port.blank?

    uri = URI("http://#{machine.warden_local_ip}:#{machine.warden_callback_port}/session-extended")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["X-Warden-Secret"] = machine.warden_callback_secret if machine.warden_callback_secret.present?
    request.body = { end_time: new_end_time.iso8601 }.to_json

    Net::HTTP.start(uri.hostname, uri.port, open_timeout: 5, read_timeout: 10) do |http|
      http.request(request)
    end
  rescue StandardError => e
    Rails.logger.error("Failed to notify warden about session extension for machine #{machine.id}: #{e.message}")
  end

  def reservation_params
    params.require(:reservation).permit(:reservation_id, :start_time, :duration, user_ids: [])
  end

  def extend_params
    params.require(:reservation).permit(:reservation_id, :extend_hours)
  end

  def create_reservation_params
    params.require(:reservation).permit(:start_datetime, :end_datetime, usersMachines: {})
  end

  def pagination_params
    params.permit(:per_page, :page)
  end

  def sorting_params
    params.permit(:sort_by, :sort_direction)
  end

  def pagy_metadata(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    }
  end

  def apply_sorting(collection)
    allowed_sort_fields = %w[id start_time end_time status notes machine_id]
    sort_prms = sorting_params
    sort_by = sort_prms[:sort_by] || "id"
    sort_direction = sort_prms[:sort_direction]&.downcase == "asc" ? :asc : :desc

    if allowed_sort_fields.include?(sort_by)
      collection.order(sort_by => sort_direction)
    else
      collection.order(id: :asc)
    end
  end

  def serialize_reservations(reservations)
    UserReservationSerializer.new(reservations).serializable_hash[:data].map { |r| r[:attributes] }
  end

  def serialize_reservation(reservation)
    UserReservationSerializer.new(reservation).serializable_hash[:data][:attributes]
  end

  def parse_datetime(datetime)
    return datetime unless datetime.is_a?(String)

    Time.zone.parse(datetime)
  end

  def calculate_duration_in_hours(start_time, end_time)
    ((end_time - start_time) / 3600.0).round(2)
  end

  def calculate_max_extend_hours(reservation)
    machine = reservation.machine
    current_end = reservation.end_time

    # 1. Find next reservation on the same machine after current end
    next_reservation = Reservation.where(machine_id: machine.id, status: [ :confirmed, :active ])
      .where.not(id: reservation.id)
      .where("start_time >= ?", current_end)
      .order(:start_time)
      .first

    max_by_next_reservation = next_reservation ? ((next_reservation.start_time - current_end) / 1.hour).floor : Float::INFINITY

    # 2. Machine work hours limit
    end_work_hour = machine.end_work_hours.hour
    start_work_hour = machine.start_work_hours.hour
    reservation_date = current_end.to_date

    # Handle past-midnight work hours
    if end_work_hour <= start_work_hour
      # Machine works past midnight (e.g., 13:00-01:00)
      machine_end_time = Time.zone.local(reservation_date.year, reservation_date.month, reservation_date.day) + 24 * 3600
    elsif end_work_hour == 0
      machine_end_time = Time.zone.local(reservation_date.year, reservation_date.month, reservation_date.day) + 24 * 3600
    else
      machine_end_time = Time.zone.local(reservation_date.year, reservation_date.month, reservation_date.day, end_work_hour, 0, 0)
    end

    max_by_machine_hours = [ (machine_end_time - current_end) / 1.hour, 0 ].max.floor

    # 3. Available playhours
    max_by_playhours = current_user.available_playhours.floor

    # Return the minimum of all constraints
    [ max_by_next_reservation, max_by_machine_hours, max_by_playhours ].min.clamp(0, Float::INFINITY)
  end

  def has_overlapping_confirmed_reservation?(user, start_time, end_time)
    user.reservations.where(status: :confirmed).any? do |res|
      (start_time < res.end_time) && (end_time > res.start_time)
    end
  end

  def deduct_hours_from_machine_hours(user, hours_needed, reservation)
    remaining_hours = hours_needed
    current_time = Time.current

    # Get available machine_hours for playhours in priority order
    # Priority:
    # 1. Expiring hours (expires=true), soonest first
    # 2. Non-convertible hours (convertible=false), oldest first
    # 3. Convertible hours (convertible=true), oldest first

    expiring_hours = user.machine_hours
      .where(hours_type: :playhours, hours_status: :active, expires: true)
      .where("expires_at > ?", current_time)
      .where("hours_amount > 0")
      .order("expires_at ASC, created_at ASC")

    non_convertible_hours = user.machine_hours
      .where(hours_type: :playhours, hours_status: :active, expires: false, convertible: false)
      .where("hours_amount > 0")
      .order("created_at ASC")

    convertible_hours = user.machine_hours
      .where(hours_type: :playhours, hours_status: :active, expires: false, convertible: true)
      .where("hours_amount > 0")
      .order("created_at ASC")

    # Process in priority order
    [ expiring_hours, non_convertible_hours, convertible_hours ].each do |hours_collection|
      hours_collection.each do |machine_hour|
        break if remaining_hours <= 0

        hours_to_deduct = [ remaining_hours, machine_hour.hours_amount ].min.to_f

        # Update machine_hour
        machine_hour.hours_amount -= hours_to_deduct
        machine_hour.used_hours = (machine_hour.used_hours || 0) + hours_to_deduct

        unless machine_hour.save
          return { success: false, error: "Failed to update machine hours: #{machine_hour.errors.full_messages.join(', ')}" }
        end

        # Create hour_transaction
        transaction = HourTransaction.create(
          sender_id: user.id,
          receiver: reservation,
          hours_amount: hours_to_deduct,
          transaction_type: "reservation_cost",
          notice: "Deducted #{hours_to_deduct} hours from machine_hour ID: #{machine_hour.id} for reservation ID: #{reservation.id}"
        )

        unless transaction.persisted?
          return { success: false, error: "Failed to create transaction: #{transaction.errors.full_messages.join(', ')}" }
        end

        remaining_hours -= hours_to_deduct
      end
    end

    if remaining_hours > 0
      return { success: false, error: "Insufficient hours after deduction. Still need: #{remaining_hours}" }
    end

    { success: true }
  end

  def render_reservation_creation_response(created_reservations, errors)
    if errors.empty?
      render json: { reservations: serialize_reservations(created_reservations) }, status: :created
    else
      render json: {
        message: "Some reservations failed to create",
        created: 0,
        failed: errors.count,
        errors: errors
      }, status: :unprocessable_entity
    end
  end

  def refund_hours_to_creator(reservation)
    creator = reservation.creator

    # Find the original deduction transactions (creator paid the hours)
    deduction_transactions = HourTransaction.where(
      sender_id: creator.id,
      receiver: reservation,
      transaction_type: "reservation_cost"
    )

    total_refunded = 0

    deduction_transactions.each do |original_txn|
      # Extract machine_hour ID from the notice
      machine_hour_id = original_txn.notice&.match(/machine_hour ID: (\d+)/)&.[](1)&.to_i
      machine_hour = MachineHour.find_by(id: machine_hour_id) if machine_hour_id

      if machine_hour
        # Refund hours back to the original machine_hour
        machine_hour.hours_amount += original_txn.hours_amount
        machine_hour.used_hours = [ 0, (machine_hour.used_hours || 0) - original_txn.hours_amount ].max
        machine_hour.hours_status = :active if machine_hour.hours_status == "reserved"
        machine_hour.save!
      else
        # If original machine_hour not found, create a new one for the creator
        MachineHour.create!(
          user: creator,
          hours_type: :playhours,
          hours_status: :active,
          hours_amount: original_txn.hours_amount,
          used_hours: 0,
          expires: false,
          convertible: true
        )
      end

      # Create refund transaction
      HourTransaction.create!(
        sender_id: creator.id,
        receiver: reservation,
        hours_amount: original_txn.hours_amount,
        transaction_type: "reservation_refund",
        notice: "Refunded #{original_txn.hours_amount} hours for cancelled reservation ID: #{reservation.id}"
      )

      total_refunded += original_txn.hours_amount
    end

    total_refunded
  end

  def get_blocking_reservations_for_current_user(date)
    # Get all blocking reservations for current user on a specific date
    # This includes ALL of user's own reservations (any status) and confirmed/active from others
    Reservation
      .where("DATE(start_time) = ?", date)
      .where("user_id = ? OR status IN (?)", current_user.id, [ :confirmed, :active ])
      .includes(:machine)
      .order(:start_time)
  end

  def build_date_range(base_date)
    today = Date.today
    dates = []

    2.downto(1).each do |days_ago|
      previous_date = base_date - days_ago.days
      dates << previous_date if previous_date >= today
    end

    dates << base_date
    (1..3).each { |days_ahead| dates << base_date + days_ahead.days }
    dates
  end

  def find_available_slots(date, start_work_hour, end_work_hour, blocking_reservations, duration,
                           requested_minute = 0, app_opening_hour = nil, app_closing_hour = nil,
                           min_hours_before = 0, now = Time.current)
    available_slots = []
    duration_hours = duration.to_f

    # end_work_hour == 0 means midnight (end of day), treat as next day 00:00
    work_end_time = if end_work_hour == 0
      Time.zone.local(date.year, date.month, date.day) + 24 * 3600
    else
      Time.zone.local(date.year, date.month, date.day, end_work_hour, 0, 0)
    end

    app_opening_time = app_opening_hour ? Time.zone.local(date.year, date.month, date.day, app_opening_hour, 0, 0) : nil
    app_closing_time = app_closing_hour ? Time.zone.local(date.year, date.month, date.day, app_closing_hour, 0, 0) : nil

    slot_start = Time.zone.local(date.year, date.month, date.day, start_work_hour, requested_minute, 0)

    while slot_start < work_end_time
      slot_end = slot_start + (duration_hours * 3600)

      if slot_end <= work_end_time && slot_start >= now && !has_time_conflict?(slot_start, slot_end, blocking_reservations)
        # Slots outside AppSetting opening/closing hours require sufficient lead time
        if app_opening_time && app_closing_time
          outside_app_hours = slot_start < app_opening_time || slot_end > app_closing_time
          available_slots << slot_start unless outside_app_hours && now + min_hours_before.hours > slot_start
        else
          available_slots << slot_start
        end
      end

      slot_start += 3600
    end

    available_slots
  end

  def has_time_conflict?(start_time, end_time, reservations)
    reservations.any? { |res| (start_time < res.end_time) && (end_time > res.start_time) }
  end

  def machines_with_overlapping_confirmed_reservations(start_time, end_time, available_machines)
    overlapping_machine_ids = Reservation.where(status: :confirmed)
      .where("(start_time < ? AND end_time > ?) OR (start_time < ? AND end_time > ?) OR (start_time >= ? AND end_time <= ?)",
             end_time, start_time, start_time, end_time, start_time, end_time)
      .pluck(:machine_id)
      .uniq

    available_machines.where(id: overlapping_machine_ids)
  end
end
