class AdminMachineHourSerializer
  include JSONAPI::Serializer
  attributes :id, :hours_amount, :start_amount, :hours_type, :hours_status, :expires
  belongs_to :user, serializer: AdminUserSerializer

  attribute :expires_at do |object|
    object.expires_at&.strftime("%Y-%m-%dT%H:%M:%S")
  end

  attribute :created_at do |object|
    object.created_at&.strftime("%Y-%m-%dT%H:%M:%S")
  end

  attribute :updated_at do |object|
    object.updated_at&.strftime("%Y-%m-%dT%H:%M:%S")
  end
end
