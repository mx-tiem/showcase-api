class UserReservationSerializer
  include JSONAPI::Serializer
  attributes :id, :status

  attribute :start_time do |object|
    object.start_time&.iso8601
  end

  attribute :end_time do |object|
    object.end_time&.iso8601
  end

  attribute :user do |object|
    UserUserSerializer.new(object.user).serializable_hash[:data][:attributes]
  end

  attribute :machine do |object|
    UserMachineSerializer.new(object.machine).serializable_hash[:data][:attributes]
  end

  attribute :creator do |object|
    UserUserSerializer.new(object.creator).serializable_hash[:data][:attributes]
  end
end
