class AdminHourTransactionSerializer
  include JSONAPI::Serializer
  attributes :id, :hours_amount, :transaction_type, :notice

  attribute :created_at do |object|
    object.created_at&.strftime("%Y-%m-%dT%H:%M:%S")
  end

  attribute :updated_at do |object|
    object.updated_at&.strftime("%Y-%m-%dT%H:%M:%S")
  end

  attribute :sender do |object|
    {
      id: object.sender.id,
      email: object.sender.email,
      name: object.sender.name,
      role: object.sender.role
    }
  end

  attribute :receiver do |object|
    receiver_data = {
      id: object.receiver.id,
      type: object.receiver_type
    }

    # Include different attributes based on receiver type
    if object.receiver_type == "User"
      receiver_data.merge!({
        email: object.receiver.email,
        name: object.receiver.name,
        role: object.receiver.role
      })
    elsif object.receiver_type == "Reservation"
      receiver_data.merge!({
        name: "Reservation ID: #{object.receiver.id}"
      })
    end

    receiver_data
  end
end
