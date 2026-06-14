class GamePlay < ApplicationRecord
  belongs_to :game
  belongs_to :user
  belongs_to :machine, optional: true
end
