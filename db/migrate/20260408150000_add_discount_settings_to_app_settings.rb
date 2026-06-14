class AddDiscountSettingsToAppSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :app_settings, :max_play_discount, :decimal, precision: 5, scale: 2, default: 10, null: false
    add_column :app_settings, :max_play_discount_hours_required, :integer, default: 100, null: false
  end
end
