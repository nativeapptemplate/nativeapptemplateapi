class ItemTagNotifier < ApplicationNotifier
  deliver_by :action_push_native do |config|
    config.devices = -> { ApplicationPushDevice.where(owner: recipient) }
    config.format = -> {
      {
        title: title,
        body: body,
        # iOS plays no sound without aps.sound in the payload
        sound: "default"
      }
    }
    # No url: the apps open no screen for an item tag
    config.with_data = -> { {} }
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
  end
end
