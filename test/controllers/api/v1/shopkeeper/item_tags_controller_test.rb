require "test_helper"

class Api::V1::Shopkeeper::ItemTagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
    @shop = @shopkeeper.created_shops.first
    @item_tag = @shop.item_tags.first
  end

  # index
  test "index returns item_tags" do
    get api_v1_shopkeeper_shop_item_tags_url(@shop), headers: @shopkeeper.create_new_auth_token
    assert_response :success
    assert_includes response.parsed_body["data"].map { |t| t["attributes"]["queue_number"] }, @item_tag.queue_number
  end

  test "index returns pagination meta" do
    get api_v1_shopkeeper_shop_item_tags_url(@shop), headers: @shopkeeper.create_new_auth_token
    assert_response :success

    meta = response.parsed_body["meta"]
    assert_not_nil meta
    assert_equal 1, meta["current_page"]
    assert_equal @shop.item_tags.count, meta["total_count"]
    assert meta["total_pages"].present?
    assert meta["limit"].present?
  end

  test "index without page param returns up to 1000 items for backward compat" do
    get api_v1_shopkeeper_shop_item_tags_url(@shop), headers: @shopkeeper.create_new_auth_token
    assert_response :success

    meta = response.parsed_body["meta"]
    assert_equal 1000, meta["limit"]
    assert_equal @shop.item_tags.count, response.parsed_body["data"].size
  end

  test "index with page param paginates with default limit" do
    get api_v1_shopkeeper_shop_item_tags_url(@shop, page: 1), headers: @shopkeeper.create_new_auth_token
    assert_response :success

    meta = response.parsed_body["meta"]
    assert_equal Pagy::OPTIONS[:limit], meta["limit"]
    assert_equal 1, meta["current_page"]
  end

  test "index with page param beyond last page returns empty data" do
    get api_v1_shopkeeper_shop_item_tags_url(@shop, page: 9999), headers: @shopkeeper.create_new_auth_token
    assert_response :success

    assert_empty response.parsed_body["data"]
    meta = response.parsed_body["meta"]
    assert_equal 9999, meta["current_page"]
  end

  test "index requires authentication" do
    get api_v1_shopkeeper_shop_item_tags_url(@shop)
    assert_response :unauthorized
  end

  # show
  test "show returns an item_tag detail" do
    get api_v1_shopkeeper_item_tag_url(@item_tag), headers: @shopkeeper.create_new_auth_token
    assert_response :success
    assert_equal response.parsed_body["data"]["attributes"]["queue_number"], @item_tag.queue_number
  end

  test "show returns 404 for nonexistent item_tag" do
    get api_v1_shopkeeper_item_tag_url(id: "nonexistent-uuid"),
      headers: @shopkeeper.create_new_auth_token

    assert_response :not_found
    assert_equal 404, response.parsed_body["code"]
    assert_equal I18n.t("api.shopkeeper.item_tags.not_found"), response.parsed_body["error_message"]
  end

  # create
  test "create creates a new item_tag" do
    assert_difference "ItemTag.count", 1 do
      post api_v1_shopkeeper_shop_item_tags_url(@shop),
        params: {item_tag: {queue_number: "Z99"}},
        headers: @shopkeeper.create_new_auth_token
    end

    assert_response :created
    assert_equal "Z99", response.parsed_body["data"]["attributes"]["queue_number"]
  end

  test "create returns validation error with blank queue_number" do
    assert_no_difference "ItemTag.count" do
      post api_v1_shopkeeper_shop_item_tags_url(@shop),
        params: {item_tag: {queue_number: ""}},
        headers: @shopkeeper.create_new_auth_token
    end

    assert_response :unprocessable_entity
    assert_equal 422, response.parsed_body["code"]
    assert response.parsed_body["error_message"].present?
  end

  test "create returns validation error with duplicate queue_number" do
    assert_no_difference "ItemTag.count" do
      post api_v1_shopkeeper_shop_item_tags_url(@shop),
        params: {item_tag: {queue_number: @item_tag.queue_number}},
        headers: @shopkeeper.create_new_auth_token
    end

    assert_response :unprocessable_entity
    assert_equal 422, response.parsed_body["code"]
  end

  test "create returns validation error with invalid queue_number format" do
    assert_no_difference "ItemTag.count" do
      post api_v1_shopkeeper_shop_item_tags_url(@shop),
        params: {item_tag: {queue_number: "A"}},
        headers: @shopkeeper.create_new_auth_token
    end

    assert_response :unprocessable_entity
    assert_equal 422, response.parsed_body["code"]
  end

  # update
  test "update succeeds with valid queue_number" do
    patch api_v1_shopkeeper_item_tag_url(@item_tag),
      params: {item_tag: {queue_number: "X99"}},
      headers: @shopkeeper.create_new_auth_token

    assert_response :success
    assert_equal "X99", @item_tag.reload.queue_number
  end

  test "update returns validation error with invalid queue_number" do
    patch api_v1_shopkeeper_item_tag_url(@item_tag),
      params: {item_tag: {queue_number: "A"}},
      headers: @shopkeeper.create_new_auth_token

    assert_response :unprocessable_entity
    assert_equal 422, response.parsed_body["code"]
    assert response.parsed_body["error_message"].present?
  end

  # destroy
  test "destroy deletes an item_tag" do
    assert_difference "ItemTag.count", -1 do
      delete api_v1_shopkeeper_item_tag_url(@item_tag),
        headers: @shopkeeper.create_new_auth_token
    end

    assert_response :success
  end

  test "destroy returns 404 for nonexistent item_tag" do
    delete api_v1_shopkeeper_item_tag_url(id: "nonexistent-uuid"),
      headers: @shopkeeper.create_new_auth_token

    assert_response :not_found
    assert_equal 404, response.parsed_body["code"]
  end

  # complete
  test "complete completes an item_tag" do
    patch complete_api_v1_shopkeeper_item_tag_url(@item_tag), headers: @shopkeeper.create_new_auth_token
    assert_response :success
    assert @item_tag.reload.completed?
  end

  test "complete sets already_completed when already completed" do
    @item_tag.complete!
    assert @item_tag.reload.completed?

    patch complete_api_v1_shopkeeper_item_tag_url(@item_tag), headers: @shopkeeper.create_new_auth_token
    assert_response :success
    assert @item_tag.reload.already_completed
  end

  # reset
  test "reset resets an item_tag" do
    @item_tag.complete!
    assert @item_tag.reload.completed?

    patch reset_api_v1_shopkeeper_item_tag_url(@item_tag), headers: @shopkeeper.create_new_auth_token
    assert_response :success
    assert @item_tag.reload.idled?
  end
end
