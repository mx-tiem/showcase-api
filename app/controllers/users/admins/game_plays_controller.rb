class Users::Admins::GamePlaysController < Users::AdminsController
  include Pagy::Method

  def game_plays_for_user
    user = User.find(params[:user_id])

    collection = GamePlay.where(user: user)
                         .includes(:game, :machine)
                         .order(play_started_at: :desc)

    pagy, game_plays = pagy(:offset, collection, limit: pagination_params[:per_page] || 10)

    render json: {
      game_plays: serialize_game_plays(game_plays),
      summary: build_summary(user),
      pagy: pagy_metadata(pagy)
    }
  end

  private

  def pagination_params
    params.permit(:per_page, :page)
  end

  def pagy_metadata(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    }
  end

  def serialize_game_plays(game_plays)
    game_plays.map do |gp|
      {
        id: gp.id,
        game_name: gp.game.name,
        game_genre: gp.game.genre,
        machine_name: gp.machine&.name,
        play_started_at: gp.play_started_at&.iso8601,
        play_ended_at: gp.play_ended_at&.iso8601,
        duration_minutes: calculate_duration(gp)
      }
    end
  end

  def calculate_duration(game_play)
    return nil unless game_play.play_started_at
    end_time = game_play.play_ended_at || Time.current
    ((end_time - game_play.play_started_at) / 60).round
  end

  def build_summary(user)
    all_plays = GamePlay.where(user: user).includes(game: { logo_attachment: :blob })

    games_hash = {}
    all_plays.each do |gp|
      game = gp.game
      games_hash[game.id] ||= { game: game, total_minutes: 0, session_count: 0 }
      games_hash[game.id][:total_minutes] += calculate_duration(gp) || 0
      games_hash[game.id][:session_count] += 1
    end

    games_hash.values
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
  end
end
