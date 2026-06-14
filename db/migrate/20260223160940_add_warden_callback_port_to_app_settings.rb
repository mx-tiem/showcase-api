class AddWardenCallbackPortToAppSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :app_settings, :warden_callback_port, :integer
  end
end
