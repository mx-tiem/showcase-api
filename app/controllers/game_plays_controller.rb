class GamePlaysController < ApplicationController
  # Called by WardenController to start a new gameplay session.
  # Automatically ends any active session for the user before starting a new one.
  def self.start_play(user:, game:, machine: nil)
    # End any currently active gameplay sessions for this user
    GamePlay.where(user: user, play_ended_at: nil).update_all(play_ended_at: Time.current)

    GamePlay.create(
      user: user,
      game: game,
      machine: machine,
      play_started_at: Time.current
    )
  end

  # Called by WardenController to end a gameplay session.
  # Can find the session by game_play_id or by finding the active session for a user.
  def self.end_play(game_play_id: nil, user_id: nil)
    game_play = if game_play_id.present?
      GamePlay.find_by(id: game_play_id)
    elsif user_id.present?
      GamePlay.where(user_id: user_id, play_ended_at: nil)
              .order(play_started_at: :desc)
              .first
    end

    return { error: "Active game play session not found.", status: :not_found } unless game_play
    return { error: "Game play session already ended.", status: :unprocessable_entity } if game_play.play_ended_at.present?

    if game_play.update(play_ended_at: Time.current)
      { game_play: game_play, status: :ok }
    else
      { errors: game_play.errors.full_messages, status: :unprocessable_entity }
    end
  end
end
