require "test_helper"

class Api::V1::Shopkeeper::DevicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
  end

  test "create requires authentication" do
    post api_v1_shopkeeper_devices_url,
      params: {device: {token: "abc123", platform: "apple"}}
    assert_response :unauthorized
  end

  test "create registers a new device and returns 201" do
    assert_difference -> { ApplicationPushDevice.count }, 1 do
      post api_v1_shopkeeper_devices_url,
        params: {device: {token: "abc123", platform: "apple", bundle_id: "com.nativeapptemplate.example"}},
        headers: @shopkeeper.create_new_auth_token
    end
    assert_response :created
    attrs = response.parsed_body["data"]["attributes"]
    assert_equal "abc123", attrs["token"]
    assert_equal "apple", attrs["platform"]
    assert_equal "com.nativeapptemplate.example", attrs["bundle_id"]
  end

  # Two first-time registrations of one token can both pass the uniqueness
  # validation; the unique index then rejects the later INSERT. Simulate the
  # other request winning: just before this request's INSERT, commit the same
  # token from a separate connection (outside the test transaction).
  test "create still succeeds when a concurrent request registered the same token first" do
    other_request = PG.connect(**ActiveRecord::Base.connection_db_config.configuration_hash.slice(:host, :port, :user, :password).merge(dbname: ActiveRecord::Base.connection_db_config.database).compact)
    racer_id = shopkeepers(:two).id
    commit_competing_row = -> {
      other_request.exec_params(<<~SQL, [racer_id])
        INSERT INTO action_push_native_devices (platform, token, owner_type, owner_id, last_active_at, created_at, updated_at)
        VALUES ('apple', 'raced', 'Shopkeeper', $1, now(), now(), now())
      SQL
    }
    ApplicationPushDevice.before_create(commit_competing_row)

    post api_v1_shopkeeper_devices_url,
      params: {device: {token: "raced", platform: "apple"}},
      headers: @shopkeeper.create_new_auth_token

    assert_response :ok
    devices = ApplicationPushDevice.where(platform: "apple", token: "raced")
    assert_equal 1, devices.count
    assert_equal @shopkeeper, devices.first.owner
  ensure
    ApplicationPushDevice.skip_callback(:create, :before, commit_competing_row)
    # The committed row is locked by this test's transaction until it rolls
    # back, so delete it from the other connection only after that
    @after_rollback = -> {
      other_request&.exec("DELETE FROM action_push_native_devices WHERE platform = 'apple' AND token = 'raced'")
      other_request&.close
    }
  end

  test "create registers a google (FCM) device and returns 201" do
    assert_difference -> { ApplicationPushDevice.count }, 1 do
      post api_v1_shopkeeper_devices_url,
        params: {device: {token: "fcm-token-123", platform: "google", bundle_id: "com.nativeapptemplate.nativeapptemplate"}},
        headers: @shopkeeper.create_new_auth_token
    end
    assert_response :created
    attrs = response.parsed_body["data"]["attributes"]
    assert_equal "fcm-token-123", attrs["token"]
    assert_equal "google", attrs["platform"]
    assert_equal "com.nativeapptemplate.nativeapptemplate", attrs["bundle_id"]
  end

  test "create returns 422 for an unsupported platform" do
    assert_no_difference -> { ApplicationPushDevice.count } do
      post api_v1_shopkeeper_devices_url,
        params: {device: {token: "abc123", platform: "android"}},
        headers: @shopkeeper.create_new_auth_token
    end
    assert_response :unprocessable_entity
    assert_equal 422, response.parsed_body["code"]
  end

  test "create with same (platform, token) does not duplicate and returns 200" do
    ApplicationPushDevice.create!(owner: @shopkeeper, token: "abc123", platform: "apple", last_active_at: 1.day.ago)

    assert_no_difference -> { ApplicationPushDevice.count } do
      post api_v1_shopkeeper_devices_url,
        params: {device: {token: "abc123", platform: "apple"}},
        headers: @shopkeeper.create_new_auth_token
    end
    assert_response :ok
  end

  test "create touches last_active_at on re-register" do
    device = ApplicationPushDevice.create!(owner: @shopkeeper, token: "abc123", platform: "apple", last_active_at: 1.day.ago)
    original = device.last_active_at

    post api_v1_shopkeeper_devices_url,
      params: {device: {token: "abc123", platform: "apple"}},
      headers: @shopkeeper.create_new_auth_token

    assert_response :ok
    assert_operator device.reload.last_active_at, :>, original
  end

  test "create rebinds device to current_shopkeeper if token previously belonged to someone else" do
    other_shopkeeper = shopkeepers(:two)
    ApplicationPushDevice.create!(owner: other_shopkeeper, token: "shared-token", platform: "apple")

    assert_no_difference -> { ApplicationPushDevice.count } do
      post api_v1_shopkeeper_devices_url,
        params: {device: {token: "shared-token", platform: "apple"}},
        headers: @shopkeeper.create_new_auth_token
    end
    assert_response :ok
    assert_equal @shopkeeper, ApplicationPushDevice.find_by(platform: "apple", token: "shared-token").owner
  end

  test "create returns 422 with missing platform" do
    post api_v1_shopkeeper_devices_url,
      params: {device: {token: "abc123"}},
      headers: @shopkeeper.create_new_auth_token
    assert_response :unprocessable_entity
    assert_equal 422, response.parsed_body["code"]
  end

  test "destroy removes the device" do
    device = ApplicationPushDevice.create!(owner: @shopkeeper, token: "abc123", platform: "apple")

    assert_difference -> { ApplicationPushDevice.count }, -1 do
      delete api_v1_shopkeeper_device_url(device),
        headers: @shopkeeper.create_new_auth_token
    end
    assert_response :no_content
  end

  test "destroy of another shopkeeper's device returns 404" do
    other = shopkeepers(:two)
    other_device = ApplicationPushDevice.create!(owner: other, token: "other-token", platform: "apple")

    assert_no_difference -> { ApplicationPushDevice.count } do
      delete api_v1_shopkeeper_device_url(other_device),
        headers: @shopkeeper.create_new_auth_token
    end
    assert_response :not_found
  end

  # Runs after the fixtures transaction has rolled back
  def after_teardown
    super
    @after_rollback&.call
  end
end
