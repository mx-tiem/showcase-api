class Users::Users::GamePlaysController < Users::UsersController
  def summary
    all_plays = GamePlay.where(user: current_user).includes(game: { logo_attachment: :blob })

    games_hash = {}
    all_plays.each do |gp|
      game = gp.game
      games_hash[game.id] ||= { game: game, total_minutes: 0, session_count: 0 }
      end_time = gp.play_ended_at || Time.current
      duration = ((end_time - gp.play_started_at) / 60).round
      games_hash[game.id][:total_minutes] += duration
      games_hash[game.id][:session_count] += 1
    end

    summary = games_hash.values
                        .sort_by { |g| -g[:total_minutes] }
                        .map do |entry|
      game = entry[:game]
      {
        game_id: game.id,
        game_name: game.name,
        logo_url: game.logo.attached? ? "/rails/active_storage/blobs/proxy/#{game.logo.signed_id}/#{game.logo.filename}" : nil,
        total_minutes: entry[:total_minutes],
        session_count: entry[:session_count]
      }
    end

    total_reservations = Reservation.where(user: current_user).count

    render json: { summary: summary, total_reservations: total_reservations }
  end
end
