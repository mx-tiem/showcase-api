class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.string :name, null: false
      t.text :description
      t.string :genre, null: false, default: "FPS"
      t.boolean :multiplayer, null: false, default: true
      t.boolean :coop, null: false, default: false
      t.boolean :controller_support, null: false, default: false
      t.string :platform, null: false, default: "PC"
      t.timestamps
    end
  end
end
