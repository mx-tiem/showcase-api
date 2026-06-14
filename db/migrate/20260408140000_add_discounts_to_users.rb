class AddDiscountsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :discount_play, :decimal, precision: 5, scale: 2, default: 0, null: false
    add_column :users, :discount_admin, :decimal, precision: 5, scale: 2, default: 0, null: false
  end
end
