class ItemTagCalledNotifier < ApplicationNotifier
  notification_methods do
    def title
      I18n.t("notifiers.item_tag_called.title", number: record.name)
    end

    def body
      I18n.t("notifiers.item_tag_called.body", shop: record.shop.name)
    end

    def url
      Rails.application.routes.url_helpers.api_v1_shopkeeper_shop_item_tag_path(
        shop_id: record.shop_id,
        id: record.id
      )
    end
  end
end
