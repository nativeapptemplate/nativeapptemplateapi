class ItemTagNotifier < ApplicationNotifier
  deliver_by :action_push_native do |config|
    config.devices = -> { ApplicationPushDevice.where(owner: recipient) }
    config.format = -> {
      {
        title: title,
        body: body,
        data: {url: url}
      }
    }
  end

  notification_methods do
    def title
      I18n.t("notifiers.item_tag.title", name: record.name)
    end

    def body
      I18n.t("notifiers.item_tag.body", shop: record.shop.name)
    end

    def url
      Rails.application.routes.url_helpers.api_v1_shopkeeper_shop_item_tag_path(
        shop_id: record.shop_id,
        id: record.id
      )
    end
  end
end
