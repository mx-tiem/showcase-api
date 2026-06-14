class CreateAppSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :app_settings do |t|
      t.time :opening_hours, null: false, default: "14:00"
      t.time :closing_hours, null: false, default: "22:00"
      t.string :working_days, array: true, null: false,
               default: %w[monday tuesday wednesday thursday friday saturday sunday]
      t.integer :free_cancellation_hours, null: false, default: 4
      t.integer :min_hours_before_reservation, null: false, default: 2

      t.timestamps
    end
  end
end
