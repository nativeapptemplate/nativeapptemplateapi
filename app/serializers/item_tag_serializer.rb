class ItemTagSerializer
  include JSONAPI::Serializer
  # Not cached: shop_name comes from the shop, and the cache key only tracks
  # the item tag, so renaming the shop served the old name for up to an hour

  attributes :shop_id,
    :name,
    :description,
    :position,
    :state,
    :completed_at,
    :created_at,
    :updated_at

  belongs_to :shop

  attribute :shop_name do |item_tag|
    item_tag.shop.name
  end
end
