require "test_helper"

class Api::V1::Shopkeeper::DevicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
  end

  test "create requires authentication" do
    post api_v1_shopkeeper_devices_url,
      params: {device: {token: "abc123", platform: "ios"}}
    assert_response :unauthorized
  end

  test "create registers a new device and returns 201" do
    assert_difference -> { Device.count }, 1 do
      post api_v1_shopkeeper_devices_url,
        params: {device: {token: "abc123", platform: "ios", bundle_id: "com.nativeapptemplate.example"}},
        headers: @shopkeeper.create_new_auth_token
    end
    assert_response :created
    attrs = response.parsed_body["data"]["attributes"]
    assert_equal "abc123", attrs["token"]
    assert_equal "ios", attrs["platform"]
    assert_equal "com.nativeapptemplate.example", attrs["bundle_id"]
  end

  test "create with same (platform, token) does not duplicate and returns 200" do
    Device.create!(shopkeeper: @shopkeeper, token: "abc123", platform: "ios", last_active_at: 1.day.ago)

    assert_no_difference -> { Device.count } do
      post api_v1_shopkeeper_devices_url,
        params: {device: {token: "abc123", platform: "ios"}},
        headers: @shopkeeper.create_new_auth_token
    end
    assert_response :ok
  end

  test "create touches last_active_at on re-register" do
    device = Device.create!(shopkeeper: @shopkeeper, token: "abc123", platform: "ios", last_active_at: 1.day.ago)
    original = device.last_active_at

    post api_v1_shopkeeper_devices_url,
      params: {device: {token: "abc123", platform: "ios"}},
      headers: @shopkeeper.create_new_auth_token

    assert_response :ok
    assert_operator device.reload.last_active_at, :>, original
  end

  test "create rebinds device to current_shopkeeper if token previously belonged to someone else" do
    other_shopkeeper = shopkeepers(:two)
    Device.create!(shopkeeper: other_shopkeeper, token: "shared-token", platform: "ios")

    assert_no_difference -> { Device.count } do
      post api_v1_shopkeeper_devices_url,
        params: {device: {token: "shared-token", platform: "ios"}},
        headers: @shopkeeper.create_new_auth_token
    end
    assert_response :ok
    assert_equal @shopkeeper, Device.find_by(platform: "ios", token: "shared-token").shopkeeper
  end

  test "create returns 422 with missing platform" do
    post api_v1_shopkeeper_devices_url,
      params: {device: {token: "abc123"}},
      headers: @shopkeeper.create_new_auth_token
    assert_response :unprocessable_entity
    assert_equal 422, response.parsed_body["code"]
  end

  test "destroy removes the device" do
    device = Device.create!(shopkeeper: @shopkeeper, token: "abc123", platform: "ios")

    assert_difference -> { Device.count }, -1 do
      delete api_v1_shopkeeper_device_url(device),
        headers: @shopkeeper.create_new_auth_token
    end
    assert_response :no_content
  end

  test "destroy of another shopkeeper's device returns 404" do
    other = shopkeepers(:two)
    other_device = Device.create!(shopkeeper: other, token: "other-token", platform: "ios")

    assert_no_difference -> { Device.count } do
      delete api_v1_shopkeeper_device_url(other_device),
        headers: @shopkeeper.create_new_auth_token
    end
    assert_response :not_found
  end
end
