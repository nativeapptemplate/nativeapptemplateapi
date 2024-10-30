class ShopSerializer
  include JSONAPI::Serializer

  belongs_to :account

  attributes :name,
    :description,
    :time_zone
end
