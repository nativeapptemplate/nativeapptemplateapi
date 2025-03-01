class ItemTagSerializer
  include JSONAPI::Serializer
  cache_options store: Rails.cache, namespace: "jsonapi-serializer", expires_in: 1.hour

  attributes :shop_id,
    :queue_number,
    :state,
    :scan_state,
    :customer_read_at,
    :completed_at,
    :already_completed,
    :created_at,
    :updated_at

  belongs_to :shop

  attribute :shop_name do |item_tag|
    item_tag.shop.name
  end
end
