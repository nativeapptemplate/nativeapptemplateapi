require "test_helper"

# The mobile apps parse every API error as {code, error_message}. GET requests
# carry no Content-Type, so errors must be JSON regardless of request headers.
class ApiErrorResponsesTest < ActionDispatch::IntegrationTest
  MISSING_ID = "00000000-0000-0000-0000-000000000000"

  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @headers = @shopkeeper.create_new_auth_token
  end

  test "a missing shop returns 404 JSON" do
    get api_v1_shopkeeper_shop_url(MISSING_ID), headers: @headers

    assert_json_error 404, I18n.t("not_found")
  end

  test "another shopkeeper's shop returns 404 JSON" do
    other = shopkeepers(:two)
    other.create_default_account

    get api_v1_shopkeeper_shop_url(other.created_shops.first), headers: @headers

    assert_json_error 404, I18n.t("not_found")
  end

  test "a missing account returns 404 JSON" do
    get api_v1_shopkeeper_account_url(MISSING_ID), headers: @headers

    assert_json_error 404, I18n.t("not_found")
  end

  test "a missing device returns 404 JSON" do
    delete api_v1_shopkeeper_device_url(MISSING_ID), headers: @headers

    assert_json_error 404, I18n.t("not_found")
  end

  test "a missing item_tags parent shop returns 404 JSON" do
    get api_v1_shopkeeper_shop_item_tags_url(MISSING_ID), headers: @headers

    assert_json_error 404, I18n.t("not_found")
  end

  test "a missing required parameter returns 400 JSON" do
    post api_v1_shopkeeper_devices_url, params: {}, headers: @headers

    assert_json_error 400, I18n.t("bad_request")
  end

  test "an unknown API route returns 404 JSON" do
    # Like production: no debug page, so the routing error reaches ErrorsController
    with_detailed_exceptions(false) do
      get "/api/v1/shopkeeper/does_not_exist", headers: @headers
    end

    assert_json_error 404, "Not found."
  end

  test "an unknown account-prefixed API route returns 404 JSON" do
    account = @shopkeeper.accounts.first

    with_detailed_exceptions(false) do
      get "/#{account.id}/api/v1/shopkeeper/does_not_exist", headers: @headers
    end

    assert_json_error 404, "Not found."
  end

  test "an unknown non-API route still returns the HTML 404 page" do
    with_detailed_exceptions(false) do
      get "/does_not_exist"
    end

    assert_response :not_found
    assert_equal "text/html", response.media_type
  end

  private

  def with_detailed_exceptions(value)
    env_config = Rails.application.env_config
    original = env_config["action_dispatch.show_detailed_exceptions"]
    env_config["action_dispatch.show_detailed_exceptions"] = value
    yield
  ensure
    env_config["action_dispatch.show_detailed_exceptions"] = original
  end

  def assert_json_error(code, message)
    assert_response code
    assert_equal "application/json", response.media_type
    assert_equal({"code" => code, "error_message" => message}, response.parsed_body)
  end
end
