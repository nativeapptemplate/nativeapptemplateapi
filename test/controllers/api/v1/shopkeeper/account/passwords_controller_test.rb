require "test_helper"

class Api::V1::Shopkeeper::Account::PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "returns unauthorized if shopkeeper not valid" do
    patch api_v1_shopkeeper_account_password_url
    assert_response :unauthorized
  end

  test "changes password on success" do
    shopkeeper = shopkeepers(:one)
    patch api_v1_shopkeeper_account_password_url, params: {shopkeeper: {current_password: "password", password: "new_password", password_confirmation: "new_password"}}, headers: shopkeeper.create_new_auth_token
    assert_response :success
    shopkeeper.reload
    assert shopkeeper.valid_password?("new_password")
  end

  test "errors if current password doesn't match" do
    shopkeeper = shopkeepers(:one)
    patch api_v1_shopkeeper_account_password_url, params: {shopkeeper: {current_password: "wrong_password", password: "new_password", password_confirmation: "new_password"}}, headers: shopkeeper.create_new_auth_token
    assert_response :unprocessable_entity
    assert_not_nil json_response.dig("error_message")
  end

  test "errors if password confirmation doesn't match" do
    shopkeeper = shopkeepers(:one)
    patch api_v1_shopkeeper_account_password_url, params: {shopkeeper: {current_password: "password", password: "new_password", password_confirmation: "wrong_password"}}, headers: shopkeeper.create_new_auth_token
    assert_response :unprocessable_entity
    assert_not_nil json_response.dig("error_message")
  end
end
