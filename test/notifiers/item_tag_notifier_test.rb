require "test_helper"

class ItemTagNotifierTest < ActiveSupport::TestCase
  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @shop = @shopkeeper.created_shops.first
    @item_tag = @shop.item_tags.first
  end

  test "delivering creates a Noticed::Event" do
    assert_difference -> { Noticed::Event.count }, 1 do
      ItemTagNotifier.with(record: @item_tag).deliver(@shopkeeper)
    end
  end

  test "delivering creates a Noticed::Notification for the recipient" do
    assert_difference -> { Noticed::Notification.count }, 1 do
      ItemTagNotifier.with(record: @item_tag).deliver(@shopkeeper)
    end
    notification = @shopkeeper.notifications.last
    assert_not_nil notification
    assert_equal @item_tag, notification.record
  end

  test "title and body resolve from i18n on the notification" do
    ItemTagNotifier.with(record: @item_tag).deliver(@shopkeeper)
    notification = @shopkeeper.notifications.last

    assert_equal I18n.t("notifiers.item_tag.title", name: @item_tag.name), notification.title
    assert_equal I18n.t("notifiers.item_tag.body", shop: @shop.name), notification.body
  end
end
