class ItemTagNotifier < ApplicationNotifier
  deliver_by :action_push_native do |config|
    config.devices = -> { ApplicationPushDevice.where(owner: recipient) }
    config.format = -> {
      {
        title: title,
        body: body
      }
    }
    config.with_data = -> { {url: url} }
    config.with_apple = -> { {} }
    config.with_google = -> { {} }
  end

  notification_methods do
    def title
      I18n.t("notifiers.item_tag.title", shop: record.shop.name)
    end

    def body
      I18n.t("notifiers.item_tag.body", name: record.name)
    end

    def url
      Rails.application.routes.url_helpers.api_v1_shopkeeper_item_tag_path(record.id)
    end
  end
end
