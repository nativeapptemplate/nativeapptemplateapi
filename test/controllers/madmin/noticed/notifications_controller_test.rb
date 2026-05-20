require "test_helper"

class Madmin::Noticed::NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = AdminUser.create!(name: "Admin", email: "admin@example.com", password: "password")

    shopkeeper = shopkeepers(:one)
    shopkeeper.create_default_account
    item_tag = shopkeeper.created_shops.first.item_tags.first
    ItemTagNotifier.with(record: item_tag).deliver(shopkeeper)
    @notification = shopkeeper.notifications.last
  end

  def sign_in_admin
    post admin_session_path, params: {email: @admin_user.email, password: "password"}
  end

  test "index renders for authenticated admin" do
    sign_in_admin
    get madmin_noticed_notifications_path
    assert_response :success
  end

  test "show renders for authenticated admin" do
    sign_in_admin
    get madmin_noticed_notification_path(@notification)
    assert_response :success
  end

  test "redirects unauthenticated users" do
    get madmin_noticed_notifications_path
    assert_redirected_to "/"
  end
end
