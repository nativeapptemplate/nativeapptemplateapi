require "test_helper"

class ShopkeeperAuth::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "returns unauthorized if shopkeeper not valid" do
    post shopkeeper_session_url
    assert_response :unauthorized
    assert response.parsed_body["error_message"]
    assert_equal I18n.t("devise_token_auth.sessions.bad_credentials"), response.parsed_body["error_message"]

    shopkeeper = shopkeepers(:one)
    post shopkeeper_session_url, params: {email: shopkeeper.email, password: "invalidpassword"}, headers: {source: "ios"}
    assert_response :unauthorized
  end

  test "returns an api token on successful auth" do
    shopkeeper = shopkeepers(:one)
    shopkeeper.create_default_account

    post shopkeeper_session_url, params: {email: shopkeeper.email, password: "password"}, headers: {source: "ios"}
    assert_response :success
    assert_not_nil response.parsed_body["data"]["attributes"]["token"]
  end

  test "signs out" do
    shopkeeper = shopkeepers(:one)
    shopkeeper.create_default_account

    delete destroy_shopkeeper_session_url, headers: shopkeeper.create_new_auth_token
    assert_response :success
  end
end
