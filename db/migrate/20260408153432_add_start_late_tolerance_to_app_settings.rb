class AddStartLateToleranceToAppSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :app_settings, :start_late_tolerance, :integer, default: 15, null: false
  end
end
