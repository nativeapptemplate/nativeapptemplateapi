class ShopkeeperSerializer
  include JSONAPI::Serializer
  cache_options store: Rails.cache, namespace: "jsonapi-serializer", expires_in: 1.hour

  attributes :email, :name, :time_zone, :locale
end
