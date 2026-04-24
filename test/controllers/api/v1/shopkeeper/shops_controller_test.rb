require "test_helper"

class Api::V1::Shopkeeper::ShopsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
    @shop = @shopkeeper.created_shops.first
  end

  # index
  test "index returns shops" do
    get api_v1_shopkeeper_shops_url, headers: @shopkeeper.create_new_auth_token
    assert_response :success
    assert_includes response.parsed_body["data"].map { |t| t["attributes"]["name"] }, @shop.name
  end

  test "index requires authentication" do
    get api_v1_shopkeeper_shops_url
    assert_response :unauthorized
  end

  # show
  test "show returns a shop detail" do
    get api_v1_shopkeeper_shop_url(@shop), headers: @shopkeeper.create_new_auth_token
    assert_response :success
    assert_equal response.parsed_body["data"]["attributes"]["name"], @shop.name
  end

  # create
  test "create creates a new shop" do
    assert_difference "Shop.count", 1 do
      post api_v1_shopkeeper_shops_url,
        params: {shop: {name: "New Shop", time_zone: "Tokyo"}},
        headers: @shopkeeper.create_new_auth_token
    end

    assert_response :created
    assert_equal "New Shop", response.parsed_body["data"]["attributes"]["name"]
  end

  test "create returns validation error with blank name" do
    assert_no_difference "Shop.count" do
      post api_v1_shopkeeper_shops_url,
        params: {shop: {name: ""}},
        headers: @shopkeeper.create_new_auth_token
    end

    assert_response :unprocessable_entity
    assert_equal 422, response.parsed_body["code"]
    assert response.parsed_body["error_message"].present?
  end

  # update
  test "update succeeds with valid name" do
    patch api_v1_shopkeeper_shop_url(@shop),
      params: {shop: {name: "Updated Shop"}},
      headers: @shopkeeper.create_new_auth_token

    assert_response :success
    assert_equal "Updated Shop", @shop.reload.name
  end

  test "update returns validation error with blank name" do
    patch api_v1_shopkeeper_shop_url(@shop),
      params: {shop: {name: ""}},
      headers: @shopkeeper.create_new_auth_token

    assert_response :unprocessable_entity
    assert_equal 422, response.parsed_body["code"]
    assert response.parsed_body["error_message"].present?
  end

  # destroy
  test "destroy deletes a shop" do
    assert_difference "Shop.count", -1 do
      delete api_v1_shopkeeper_shop_url(@shop),
        headers: @shopkeeper.create_new_auth_token
    end

    assert_response :success
  end

end
