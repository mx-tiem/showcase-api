class AddLateCancellationJobIdToReservations < ActiveRecord::Migration[8.1]
  def change
    add_column :reservations, :late_cancellation_job_id, :string
  end
end
