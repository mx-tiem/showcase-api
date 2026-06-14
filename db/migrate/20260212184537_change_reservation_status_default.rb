class ChangeReservationStatusDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :reservations, :status, from: "start", to: "new"
    Reservation.where(status: "start").update_all(status: "new")
  end
end
