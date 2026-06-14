class CreateMachineHours < ActiveRecord::Migration[8.1]
  def change
    create_table :machine_hours do |t|
      t.references :user, null: false, foreign_key: true
      t.string :hours_type, default: "playhours", null: false
      t.float :hours_amount, default: 1.0, null: false
      t.boolean :expires, default: false, null: false
      t.datetime :expires_at
      t.timestamps
    end
  end
end
