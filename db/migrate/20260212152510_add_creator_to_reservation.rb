class AddCreatorToReservation < ActiveRecord::Migration[8.1]
  def change
    add_column :reservations, :creator_id, :bigint
    add_foreign_key :reservations, :users, column: :creator_id
  end
end
