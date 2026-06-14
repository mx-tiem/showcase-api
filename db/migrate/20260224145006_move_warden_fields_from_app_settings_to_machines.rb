class MoveWardenFieldsFromAppSettingsToMachines < ActiveRecord::Migration[8.1]
  def change
    # Add warden fields to machines
    add_column :machines, :warden_callback_secret, :string
    add_column :machines, :warden_callback_port, :integer
    add_column :machines, :warden_global_ip, :string
    add_column :machines, :warden_local_ip, :string

    # Remove warden fields from app_settings
    remove_column :app_settings, :warden_callback_secret, :string
    remove_column :app_settings, :warden_callback_port, :integer
  end
end
