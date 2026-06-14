class AdminGameSerializer
  include JSONAPI::Serializer
  attributes :id, :name, :game_identifier, :description, :genre, :multiplayer, :coop, :controller_support, :platform

  attribute :logo_url do |object|
    if object.logo.attached?
      "/rails/active_storage/blobs/proxy/#{object.logo.signed_id}/#{object.logo.filename}"
    end
  end

  attribute :created_at do |object|
    object.created_at&.iso8601
  end

  attribute :updated_at do |object|
    object.updated_at&.iso8601
  end
end
