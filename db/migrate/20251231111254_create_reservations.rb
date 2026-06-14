class CreateReservations < ActiveRecord::Migration[8.1]
  def change
    create_table :reservations do |t|
      t.timestamps
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.references :user, null: false, foreign_key: true
      t.references :machine, null: false, foreign_key: true
      t.string :status, null: false, default: "new"
      t.text :notes
    end
  end
end
