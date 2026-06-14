class UserNotificationSerializer
  include JSONAPI::Serializer
  attributes :id, :title, :short_description, :long_description, :read, :icon

  attribute :created_at do |object|
    object.created_at&.iso8601
  end
end
