class AddStartWorkHoursAndEndWorkHours < ActiveRecord::Migration[8.1]
  def change
    add_column :machines, :start_work_hours, :time, null: false, default: "14:00"
    add_column :machines, :end_work_hours, :time, null: false, default: "22:00"

    add_column :machines, :working_days, :string, array: true, null: false, default: [ "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday" ]
  end
end
