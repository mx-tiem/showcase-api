class AddConvertibleToMachineHour < ActiveRecord::Migration[8.1]
  def change
    add_column :machine_hours, :convertible, :boolean, default: true, null: false
  end
end
