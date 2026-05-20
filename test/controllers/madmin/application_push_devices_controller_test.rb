require "test_helper"

class Madmin::ApplicationPushDevicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = AdminUser.create!(name: "Admin", email: "admin@example.com", password: "password")
    @device = ApplicationPushDevice.create!(
      owner: shopkeepers(:one),
      platform: "apple",
      token: "test-token"
    )
  end

  def sign_in_admin
    post admin_session_path, params: {email: @admin_user.email, password: "password"}
  end

  test "index renders for authenticated admin" do
    sign_in_admin
    get madmin_application_push_devices_path
    assert_response :success
  end

  test "show renders for authenticated admin" do
    sign_in_admin
    get madmin_application_push_device_path(@device)
    assert_response :success
  end

  test "redirects unauthenticated users" do
    get madmin_application_push_devices_path
    assert_redirected_to "/"
  end
end
