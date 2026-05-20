require "test_helper"

class ItemTagNotifierTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

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

    assert_equal I18n.t("notifiers.item_tag.title", shop: @shop.name), notification.title
    assert_equal I18n.t("notifiers.item_tag.body", name: @item_tag.name), notification.body
  end

  test "url resolves to the shallow item_tag path" do
    ItemTagNotifier.with(record: @item_tag).deliver(@shopkeeper)
    notification = @shopkeeper.notifications.last

    expected = Rails.application.routes.url_helpers.api_v1_shopkeeper_item_tag_path(@item_tag.id)
    assert_equal expected, notification.url
  end

  test "action_push_native delivery performs without raising" do
    ApplicationPushDevice.create!(owner: @shopkeeper, platform: "apple", token: "test-token")

    # Performs the Noticed delivery job (where the payload is built) but not the
    # ApplicationPushNotificationJob, so no real APNs/FCM request is made.
    assert_nothing_raised do
      perform_enqueued_jobs(except: ApplicationPushNotificationJob) do
        ItemTagNotifier.with(record: @item_tag).deliver(@shopkeeper)
      end
    end
  end
end
