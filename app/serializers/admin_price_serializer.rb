class AdminPriceSerializer
  include JSONAPI::Serializer
  attributes :id, :name, :description, :amount, :hours_type, :active, :currency, :sort_order

  attribute :price do |object|
    object.price&.to_f
  end

  attribute :created_at do |object|
    object.created_at&.iso8601
  end

  attribute :updated_at do |object|
    object.updated_at&.iso8601
  end
end
