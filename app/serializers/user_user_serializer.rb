class UserUserSerializer
  include JSONAPI::Serializer
  attributes :id, :email, :name, :username, :role, :available_playhours
end
