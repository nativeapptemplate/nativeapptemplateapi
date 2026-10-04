require "test_helper"

# Every API and auth request counts toward a per-IP limit, so one client
# can't hog the app. The mobile apps parse errors as {code, error_message},
# so the throttled response must be JSON too.
class RequestThrottleTest < ActionDispatch::IntegrationTest
  LIMIT = ApplicationController::REQUESTS_PER_IP_LIMIT

  test "the API answers 429 JSON once an IP passes the limit" do
    # Unauthenticated requests still count (401s here)
    LIMIT.times { get api_v1_shopkeeper_shops_url, headers: ip("10.1.0.1") }
    assert_response :unauthorized

    get api_v1_shopkeeper_shops_url, headers: ip("10.1.0.1")

    assert_response :too_many_requests
    assert_equal({"code" => 429, "error_message" => I18n.t("errors.messages.too_many_requests")}, response.parsed_body)
  end

  test "auth endpoints share the same per-IP limit" do
    LIMIT.times { get api_v1_shopkeeper_shops_url, headers: ip("10.1.0.2") }

    post shopkeeper_session_url, params: {email: "nobody@example.com", password: "x"}, headers: ip("10.1.0.2"), as: :json

    assert_response :too_many_requests
    assert_equal 429, response.parsed_body["code"]
  end

  test "another IP is not affected" do
    LIMIT.times { get api_v1_shopkeeper_shops_url, headers: ip("10.1.0.3") }

    get api_v1_shopkeeper_shops_url, headers: ip("10.1.0.4")

    assert_response :unauthorized
  end

  test "HTML pages are limited per IP too" do
    LIMIT.times { get shopkeeper_auth_reset_password_url, headers: ip("10.1.0.5") }
    assert_response :success

    get shopkeeper_auth_reset_password_url, headers: ip("10.1.0.5")

    assert_response :too_many_requests
  end

  private

  def ip(address) = {"REMOTE_ADDR" => address}
end
