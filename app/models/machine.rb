class Machine < ApplicationRecord
  extend Enumerize
  has_many :reservations
  has_many :game_plays

  enumerize :status, in: [ :available, :working, :maintenance ], default: :maintenance
  enumerize :machine_type, in: [ :gaming_pc, :streaming_pc, :playstation, :xbox ], default: :gaming_pc

  # Shifts this machine's priority to last among bookable machines and re-compacts.
  # Called after a reservation is created on this machine.
  def rotate_priority!
    Machine.transaction do
      pool = Machine.where(status: [ :available, :working ])
      max_priority = pool.maximum(:reservation_priority) || 0
      update!(reservation_priority: max_priority + 1)

      # Compact priorities only among bookable machines to keep them sequential
      pool.order(:reservation_priority, :id).each_with_index do |machine, index|
        machine.update_column(:reservation_priority, index)
      end
    end
  end
end
