class CreateMachines < ActiveRecord::Migration[8.1]
  def change
    create_table :machines do |t|
      t.timestamps

      t.string :name, null: false, default: ""
      t.string :machine_type, null: false
      t.string :status, null: false, default: "maintenance"
      t.text :hardware_configuration
    end
  end
end
