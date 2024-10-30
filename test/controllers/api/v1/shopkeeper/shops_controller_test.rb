require "test_helper"

class Api::V1::Shopkeeper::ShopsControllerTest < ActionDispatch::IntegrationTest
  test "returns shops" do
    shopkeeper = shopkeepers(:one)
    shopkeeper.create_default_account
    shop = shopkeeper.created_shops.first

    get api_v1_shopkeeper_shops_url, headers: shopkeeper.create_new_auth_token
    assert_response :success
    assert_includes response.parsed_body["data"].map { |t| t["attributes"]["name"] }, shop.name
  end

  test "returns a shop detail" do
    shopkeeper = shopkeepers(:one)
    shopkeeper.create_default_account
    shop = shopkeeper.created_shops.first

    get api_v1_shopkeeper_shop_url(shop), headers: shopkeeper.create_new_auth_token
    assert_response :success
    assert_equal response.parsed_body["data"]["attributes"]["name"], shop.name
  end
end
