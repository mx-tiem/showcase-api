class HourTransaction < ApplicationRecord
  extend Enumerize
  belongs_to :sender, class_name: "User"
  belongs_to :receiver, polymorphic: true

  validates :hours_amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_type, presence: true, inclusion: { in: %w[add_user_to_user add_admin_to_user remove_admin_to_user reservation_cost reservation_refund] }

  enumerize :transaction_type, in: %w[add_user_to_user add_admin_to_user remove_admin_to_user reservation_cost reservation_refund], predicates: true
end
