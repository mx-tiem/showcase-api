class CreateHourTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :hour_transactions do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :receiver, null: false, foreign_key: { to_table: :users }
      t.float :hours_amount, null: false
      t.string :transaction_type, null: false
      t.string :notice
      t.timestamps
    end
  end
end
