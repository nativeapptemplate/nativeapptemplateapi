class DeviceSerializer
  include JSONAPI::Serializer

  attributes :token,
    :platform,
    :bundle_id,
    :last_active_at,
    :created_at,
    :updated_at
end
