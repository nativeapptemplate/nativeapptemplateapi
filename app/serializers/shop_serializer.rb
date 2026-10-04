class ShopSerializer
  include JSONAPI::Serializer

  belongs_to :account

  attributes :name,
    :description,
    :time_zone

  attribute :item_tags_count do |shop|
    shop.item_tags.size
  end

  # The index preloads item_tags; count those instead of querying per shop
  attribute :completed_item_tags_count do |shop|
    shop.item_tags.loaded? ? shop.item_tags.count(&:completed?) : shop.item_tags.completed.size
  end
end
