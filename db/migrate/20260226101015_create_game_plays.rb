class CreateGamePlays < ActiveRecord::Migration[8.1]
  def change
    create_table :game_plays do |t|
      t.references :game, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :play_started_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :play_ended_at
      t.timestamps
    end
  end
end
