class AddFinishJobIdToReservations < ActiveRecord::Migration[8.1]
  def change
    add_column :reservations, :finish_job_id, :string
  end
end
