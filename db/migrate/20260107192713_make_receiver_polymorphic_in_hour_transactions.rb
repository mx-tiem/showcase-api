class MakeReceiverPolymorphicInHourTransactions < ActiveRecord::Migration[8.1]
  def up
    # Remove foreign key constraint
    remove_foreign_key :hour_transactions, column: :receiver_id

    # Add receiver_type column for polymorphic association
    add_column :hour_transactions, :receiver_type, :string

    # Set existing records to User type
    HourTransaction.update_all(receiver_type: 'User')

    # Make receiver_type not nullable
    change_column_null :hour_transactions, :receiver_type, false

    # Add index for polymorphic association
    add_index :hour_transactions, [ :receiver_type, :receiver_id ]
  end

  def down
    # Remove index
    remove_index :hour_transactions, [ :receiver_type, :receiver_id ]

    # Remove receiver_type column
    remove_column :hour_transactions, :receiver_type

    # Add back foreign key constraint
    add_foreign_key :hour_transactions, :users, column: :receiver_id
  end
end
