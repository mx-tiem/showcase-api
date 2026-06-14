class CreatePrices < ActiveRecord::Migration[8.1]
  def change
    create_table :prices do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 8, scale: 2, null: false
      t.float :amount, null: false
      t.string :hours_type, null: false, default: "playhours"
      t.boolean :active, null: false, default: true
      t.string :currency, null: false, default: "EUR"
      t.integer :sort_order, null: false, default: 0
      t.timestamps
    end
  end
end
