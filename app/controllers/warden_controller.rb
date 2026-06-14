require "net/http"

class WardenController < ApplicationController
  skip_before_action :configure_permitted_parameters
  before_action :authenticate_dojo_warden_secret!, only: [ :login, :report, :start_gameplay, :end_gameplay, :user_logged_out ]
  before_action :authenticate_user!, only: [ :command, :status ]
  before_action :authorize_admin!, only: [ :command, :status ]

  def login
    if warden_params[:login].blank? || warden_params[:password].blank?
      return render json: { error: "Login and password are required." }, status: :bad_request
    end

    user = User.find_for_database_authentication(login: warden_params[:login])

    unless user&.valid_password?(warden_params[:password])
      return render json: { error: "Invalid login credentials." }, status: :unauthorized
    end

    reservation = user.role.admin? ? nil : find_eligible_reservation(user)

    unless user.role.admin? || reservation
      return render json: { error: "No active or upcoming reservation found." }, status: :forbidden
    end

    token = generate_jwt(user)

    # Activate confirmed reservation and set machine to working
    if reservation&.status == "confirmed"
      reservation.update(status: :active)
    end

    # Set the machine status to working when a user logs in through warden
    machine = if reservation
      reservation.machine
    elsif warden_params[:machine_id].present?
      Machine.find_by(id: warden_params[:machine_id])
    end
    machine&.update(status: :working)

    render json: {
      status: {
        code: 200,
        message: "Warden login successful.",
        token: token,
        user: {
          id: user.id,
          email: user.email,
          username: user.username,
          role: user.role
        },
        reservation: reservation ? {
          id: reservation.id,
          machine_id: reservation.machine_id,
          start_time: reservation.start_time,
          end_time: reservation.end_time,
          status: reservation.status
        } : nil
      }
    }, status: :ok
  end

  def report
    machine = Machine.find_by(id: report_params[:machine_id])

    unless machine
      return render json: { error: "Machine not found." }, status: :not_found
    end

    if machine.update(
      warden_global_ip: report_params[:warden_global_ip],
      warden_local_ip: report_params[:warden_local_ip],
      warden_callback_port: report_params[:warden_callback_port],
      warden_callback_secret: report_params[:warden_callback_secret]
    )
      render json: { message: "Machine warden details updated successfully." }, status: :ok
    else
      render json: { errors: machine.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def status
    machine = Machine.find_by(id: params[:machine_id])

    unless machine
      return render json: { error: "Machine not found." }, status: :not_found
    end

    if machine.warden_local_ip.blank? || machine.warden_callback_port.blank?
      return render json: { error: "Warden connection details are not configured for this machine." }, status: :unprocessable_entity
    end

    begin
      uri = URI("http://#{machine.warden_local_ip}:#{machine.warden_callback_port}/status")
      request = Net::HTTP::Get.new(uri)
      request["Content-Type"] = "application/json"
      request["X-Warden-Secret"] = machine.warden_callback_secret if machine.warden_callback_secret.present?

      response = Net::HTTP.start(uri.hostname, uri.port, open_timeout: 5, read_timeout: 10) do |http|
        http.request(request)
      end

      warden_body = begin; JSON.parse(response.body); rescue; response.body; end

      if response.is_a?(Net::HTTPSuccess)
        render json: warden_body, status: :ok
      else
        render json: { error: "Warden responded with status #{response.code}", warden_response: warden_body }, status: :bad_gateway
      end
    rescue StandardError => e
      render json: { error: "Failed to connect to Warden: #{e.message}" }, status: :service_unavailable
    end
  end

  def command
    machine = Machine.find_by(id: params[:machine_id])

    unless machine
      return render json: { error: "Machine not found." }, status: :not_found
    end

    action = params[:command]

    unless %w[lock shutdown restart].include?(action)
      return render json: { error: "Invalid command. Allowed: lock, shutdown, restart" }, status: :bad_request
    end

    if machine.warden_local_ip.blank? || machine.warden_callback_port.blank?
      return render json: { error: "Warden connection details are not configured for this machine." }, status: :unprocessable_entity
    end

    begin
      response = send_warden_command(machine, action)
      warden_body = begin; JSON.parse(response.body); rescue; response.body; end

      if response.is_a?(Net::HTTPSuccess)
        render json: { message: "Command '#{action}' sent successfully.", warden_response: warden_body }, status: :ok
      else
        render json: { error: "Warden responded with status #{response.code}", warden_response: warden_body }, status: :bad_gateway
      end
    rescue StandardError => e
      render json: { error: "Failed to connect to Warden: #{e.message}" }, status: :service_unavailable
    end
  end

  def start_gameplay
    user = User.find_by(id: gameplay_params[:user_id])
    return render json: { error: "User not found." }, status: :not_found unless user

    game = Game.find_by(game_identifier: gameplay_params[:game_identifier])
    return render json: { error: "Game not found." }, status: :not_found unless game

    machine = Machine.find_by(id: gameplay_params[:machine_id])

    game_play = GamePlaysController.start_play(user: user, game: game, machine: machine)

    if game_play.persisted?
      render json: {
        message: "Gameplay started.",
        game_play: serialize_game_play(game_play)
      }, status: :created
    else
      render json: { errors: game_play.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def end_gameplay
    result = GamePlaysController.end_play(
      game_play_id: gameplay_params[:game_play_id],
      user_id: gameplay_params[:user_id]
    )

    if result[:error]
      return render json: { error: result[:error] }, status: result[:status]
    end

    if result[:errors]
      return render json: { errors: result[:errors] }, status: result[:status]
    end

    render json: {
      message: "Gameplay ended.",
      game_play: serialize_game_play(result[:game_play])
    }, status: :ok
  end

  def user_logged_out
    machine = Machine.find_by(id: params[:machine_id])

    unless machine
      return render json: { error: "Machine not found." }, status: :not_found
    end

    machine.update!(status: :available)

    render json: { message: "Machine #{machine.name} set to available." }, status: :ok
  end

  private

  def authenticate_dojo_warden_secret!
    provided_secret = request.headers["X-Dojo-Warden-Secret"] || request.headers["X_Dojo_Warden_Secret"] || params[:dojo_warden_secret]
    stored_secret = AppSetting.instance.dojo_warden_secret

    if stored_secret.blank?
      return render json: { error: "Dojo warden secret is not configured." }, status: :service_unavailable
    end

    unless ActiveSupport::SecurityUtils.secure_compare(provided_secret.to_s, stored_secret)
      render json: { error: "Invalid dojo warden secret." }, status: :unauthorized
    end
  end

  def warden_params
    params.require(:user).permit(:login, :password, :machine_id)
  end

  def report_params
    params.require(:report).permit(:machine_id, :warden_global_ip, :warden_local_ip, :warden_callback_port, :warden_callback_secret)
  end

  def gameplay_params
    params.permit(:user_id, :game_id, :game_identifier, :game_play_id, :machine_id)
  end

  def serialize_game_play(game_play)
    {
      id: game_play.id,
      user_id: game_play.user_id,
      game_id: game_play.game_id,
      play_started_at: game_play.play_started_at,
      play_ended_at: game_play.play_ended_at
    }
  end

  def authorize_admin!
    unless current_user&.role == "admin"
      render json: { error: "Unauthorized access" }, status: :unauthorized
    end
  end

  def send_warden_command(machine, action)
    uri = URI("http://#{machine.warden_local_ip}:#{machine.warden_callback_port}/#{action}")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["X-Warden-Secret"] = machine.warden_callback_secret if machine.warden_callback_secret.present?

    Net::HTTP.start(uri.hostname, uri.port, open_timeout: 5, read_timeout: 10) do |http|
      http.request(request)
    end
  end

  # Find a reservation that is currently active or starts within 5 minutes
  def find_eligible_reservation(user)
    now = Time.current

    user.reservations
      .where(status: %w[confirmed active])
      .where("start_time <= :buffer_time AND end_time > :now", buffer_time: now + 5.minutes, now: now)
      .order(start_time: :asc)
      .first
  end

  def generate_jwt(user)
    secret = Rails.application.credentials.devise_jwt_secret_key!
    payload = {
      sub: user.id,
      jti: user.jti,
      scp: "user",
      iat: Time.current.to_i,
      exp: 1.day.from_now.to_i
    }
    JWT.encode(payload, secret, "HS256")
  end
end
