class AddStatusToMachineHours < ActiveRecord::Migration[8.1]
  def change
    add_column :machine_hours, :hours_status, :string, null: false, default: "active"
  end
end
