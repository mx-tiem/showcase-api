class AddWardenCallbackSecretToAppSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :app_settings, :warden_callback_secret, :string
  end
end
