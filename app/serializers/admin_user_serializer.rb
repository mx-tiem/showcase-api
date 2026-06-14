class AdminUserSerializer
  include JSONAPI::Serializer
  attributes :id, :email, :name, :username, :role, :available_playhours

  attribute :discount_play do |object|
    object.discount_play&.to_f
  end

  attribute :discount_admin do |object|
    object.discount_admin&.to_f
  end

  attribute :played_hours do |object|
    object.played_hours&.to_f
  end
end
