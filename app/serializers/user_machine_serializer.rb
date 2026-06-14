class UserMachineSerializer
  include JSONAPI::Serializer
  attributes :id, :name, :machine_type
end
