class AddPlayedHoursToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :played_hours, :float, default: 0.0, null: false
  end
end
