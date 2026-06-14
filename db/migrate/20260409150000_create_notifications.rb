class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :short_description, null: false
      t.text :long_description
      t.boolean :read, null: false, default: false
      t.string :icon, default: "notifications"

      t.timestamps
    end

    add_index :notifications, [ :user_id, :read ]
    add_index :notifications, [ :user_id, :created_at ]
  end
end
