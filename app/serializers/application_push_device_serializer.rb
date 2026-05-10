class ApplicationPushDeviceSerializer
  include JSONAPI::Serializer

  set_type :device

  attributes :token,
    :platform,
    :bundle_id,
    :last_active_at,
    :created_at,
    :updated_at
end
