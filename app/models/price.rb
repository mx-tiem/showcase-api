class Price < ApplicationRecord
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :hours_type, presence: true
  validates :currency, presence: true
  validates :sort_order, numericality: { only_integer: true }

  scope :active, -> { where(active: true) }
  scope :sorted, -> { order(sort_order: :asc, name: :asc) }
end
