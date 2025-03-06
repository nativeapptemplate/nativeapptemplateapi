class ShopSerializer
  include JSONAPI::Serializer

  belongs_to :account

  attributes :name,
    :description,
    :time_zone

  attribute :item_tags_count do |shop|
    shop.item_tags.size
  end

  attribute :scanned_item_tags_count do |shop|
    shop.item_tags.scanned.size
  end

  attribute :completed_item_tags_count do |shop|
    shop.item_tags.completed.size
  end

  attribute :display_shop_server_path do |shop|
    Rails.application.routes.url_helpers.display_shop_path(shop, type: "server")
  end
end
