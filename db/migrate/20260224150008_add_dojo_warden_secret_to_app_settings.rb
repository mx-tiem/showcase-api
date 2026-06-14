class AddDojoWardenSecretToAppSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :app_settings, :dojo_warden_secret, :string
  end
end
