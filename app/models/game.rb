class Game < ApplicationRecord
  has_many :game_plays
  has_many :users, through: :game_plays
  has_one_attached :logo
end
