class AddGameIdentifierToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :game_identifier, :string
  end
end
