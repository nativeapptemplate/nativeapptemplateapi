class ShopSerializer
  include JSONAPI::Serializer

  belongs_to :account

  attributes :name,
    :description,
    :time_zone

  attribute :item_tags_count do |shop|
    shop.item_tags.size
  end

  attribute :completed_item_tags_count do |shop|
    shop.item_tags.completed.size
  end
end
