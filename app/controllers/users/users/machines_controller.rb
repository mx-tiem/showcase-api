class Users::Users::MachinesController < Users::UsersController
  def index
    machines = Machine.where(status: %w[available working]).order(:id)
    friend_ids = current_user.friends.pluck(:friend_id)

    now = Time.current
    # Preload only 'active' reservations that are happening now
    active_reservations = Reservation
      .where(status: 'active')
      .where("start_time <= ? AND end_time > ?", now, now)
      .includes(:user)
      .index_by(&:machine_id)

    # Preload ALL active game plays (no play_ended_at), not just those tied to reservations
    active_user_ids = active_reservations.values.map(&:user_id).uniq
    active_game_plays = GamePlay
      .where(play_ended_at: nil)
      .where(user_id: active_user_ids)
      .includes(:game)
      .index_by(&:user_id)

    result = machines.map do |machine|
      reservation = active_reservations[machine.id]
      user = reservation&.user
      game_play = user ? active_game_plays[user.id] : nil
      game = game_play&.game

      {
        id: machine.id,
        name: machine.name,
        machine_type: machine.machine_type,
        status: machine.status,
        current_game: game&.name,
        game_logo_url: game&.logo&.attached? ? "/rails/active_storage/blobs/proxy/#{game.logo.signed_id}/#{game.logo.filename}" : nil,
        current_user: user&.username,
        is_friend: user ? (user.id == current_user.id || friend_ids.include?(user.id)) : false
      }
    end

    render json: { machines: result }, status: :ok
  end
end
