class AddStartAmountToMachineHours < ActiveRecord::Migration[8.1]
  def change
    add_column :machine_hours, :start_amount, :float, default: 0.0, null: false
  end
end
