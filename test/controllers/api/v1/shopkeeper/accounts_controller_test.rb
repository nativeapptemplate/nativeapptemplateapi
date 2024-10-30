require "test_helper"

class Api::V1::Shopkeeper::AccountsControllerTest < ActionDispatch::IntegrationTest
  test "returns current shopkeeper accounts" do
    shopkeeper = shopkeepers(:one)
    shopkeeper.create_default_account

    get api_v1_shopkeeper_accounts_url, headers: shopkeeper.create_new_auth_token
    assert_response :success
    assert_includes response.parsed_body["data"].map { |t| t["attributes"]["name"] }, shopkeeper.accounts.first.name
  end
end
