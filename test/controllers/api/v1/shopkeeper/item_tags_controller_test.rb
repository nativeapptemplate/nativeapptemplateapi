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
    assert_includes response.parsed_body["data"].map { |t| t["attributes"]["name"] }, @item_tag.name
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
    assert_equal Pagination::DEFAULT_LIMIT, meta["limit"]
    assert_equal 1, meta["current_page"]
  end

  test "index with page param beyond last page returns empty data" do
    get api_v1_shopkeeper_shop_item_tags_url(@shop, page: 9999), headers: @shopkeeper.create_new_auth_token
    assert_response :success

    assert_empty response.parsed_body["data"]
    meta = response.parsed_body["meta"]
    assert_equal 9999, meta["current_page"]
  end

  test "index with page param splits items across pages" do
    create_item_tags(Pagination::DEFAULT_LIMIT + 5 - @shop.item_tags.count)

    get api_v1_shopkeeper_shop_item_tags_url(@shop, page: 1), headers: @shopkeeper.create_new_auth_token
    assert_response :success
    first_page_ids = response.parsed_body["data"].pluck("id")
    meta = response.parsed_body["meta"]
    assert_equal Pagination::DEFAULT_LIMIT, first_page_ids.size
    assert_equal Pagination::DEFAULT_LIMIT + 5, meta["total_count"]
    assert_equal 2, meta["total_pages"] # ceil(25 / 20) = 2

    get api_v1_shopkeeper_shop_item_tags_url(@shop, page: 2), headers: @shopkeeper.create_new_auth_token
    assert_response :success
    second_page_ids = response.parsed_body["data"].pluck("id")
    assert_equal 5, second_page_ids.size # 25 - 20 = 5 left for page 2
    assert_equal 2, response.parsed_body["meta"]["current_page"]
    assert_empty first_page_ids & second_page_ids
  end

  test "index treats invalid page params as the first page" do
    create_item_tags(Pagination::DEFAULT_LIMIT + 5 - @shop.item_tags.count)

    # Only a positive whole number selects a page. Pagy read "2abc" as page 2.
    ["0", "-1", "abc", "2abc", "1.5"].each do |page|
      get api_v1_shopkeeper_shop_item_tags_url(@shop, page: page), headers: @shopkeeper.create_new_auth_token
      assert_response :success, "page=#{page}"
      assert_equal 1, response.parsed_body["meta"]["current_page"], "page=#{page}"
      assert_equal Pagination::DEFAULT_LIMIT, response.parsed_body["data"].size, "page=#{page}"
    end
  end

  test "index treats a nested page param as the first page" do
    get api_v1_shopkeeper_shop_item_tags_url(@shop), params: {page: {x: "1"}}, headers: @shopkeeper.create_new_auth_token
    assert_response :success
    assert_equal 1, response.parsed_body["meta"]["current_page"]
  end

  test "index with a huge page number returns empty data" do
    # Larger than bigint, so it would overflow OFFSET if it reached the query
    get api_v1_shopkeeper_shop_item_tags_url(@shop, page: "9" * 30), headers: @shopkeeper.create_new_auth_token
    assert_response :success
    assert_empty response.parsed_body["data"]
  end

  test "index with no item_tags reports one empty page" do
    ActsAsTenant.with_tenant(@account) { @shop.item_tags.destroy_all }

    get api_v1_shopkeeper_shop_item_tags_url(@shop, page: 1), headers: @shopkeeper.create_new_auth_token
    assert_response :success
    assert_empty response.parsed_body["data"]
    meta = response.parsed_body["meta"]
    assert_equal 0, meta["total_count"]
    assert_equal 1, meta["total_pages"] # matches Pagy: an empty list is still one page
    assert_equal 1, meta["current_page"]
  end

  test "index requires authentication" do
    get api_v1_shopkeeper_shop_item_tags_url(@shop)
    assert_response :unauthorized
  end

  # show
  test "show returns item_tag detail" do
    get api_v1_shopkeeper_item_tag_url(@item_tag), headers: @shopkeeper.create_new_auth_token
    assert_response :success
    assert_equal response.parsed_body["data"]["attributes"]["name"], @item_tag.name
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
        params: {item_tag: {name: "Buy milk"}},
        headers: @shopkeeper.create_new_auth_token
    end

    assert_response :created
    assert_equal "Buy milk", response.parsed_body["data"]["attributes"]["name"]
  end

  test "create returns validation error with blank name" do
    assert_no_difference "ItemTag.count" do
      post api_v1_shopkeeper_shop_item_tags_url(@shop),
        params: {item_tag: {name: ""}},
        headers: @shopkeeper.create_new_auth_token
    end

    assert_response :unprocessable_entity
    assert_equal 422, response.parsed_body["code"]
    assert response.parsed_body["error_message"].present?
  end

  test "create allows duplicate name within the same shop" do
    assert_difference "ItemTag.count", 1 do
      post api_v1_shopkeeper_shop_item_tags_url(@shop),
        params: {item_tag: {name: @item_tag.name}},
        headers: @shopkeeper.create_new_auth_token
    end

    assert_response :created
  end

  # update
  test "update succeeds with valid name" do
    patch api_v1_shopkeeper_item_tag_url(@item_tag),
      params: {item_tag: {name: "Buy bread"}},
      headers: @shopkeeper.create_new_auth_token

    assert_response :success
    assert_equal "Buy bread", @item_tag.reload.name
  end

  test "update returns validation error with blank name" do
    patch api_v1_shopkeeper_item_tag_url(@item_tag),
      params: {item_tag: {name: ""}},
      headers: @shopkeeper.create_new_auth_token

    assert_response :unprocessable_entity
    assert_equal 422, response.parsed_body["code"]
    assert response.parsed_body["error_message"].present?
  end

  # State changes only go through the complete/idle events, which record
  # completed_by/completed_at and send the notification.
  test "update ignores state and leaves the state machine in charge" do
    assert @item_tag.idled?

    assert_no_difference "Noticed::Event.count" do
      patch api_v1_shopkeeper_item_tag_url(@item_tag),
        params: {item_tag: {name: "Buy bread", state: "completed"}},
        headers: @shopkeeper.create_new_auth_token
    end

    assert_response :success
    @item_tag.reload
    assert_equal "Buy bread", @item_tag.name
    assert @item_tag.idled?
    assert_nil @item_tag.completed_at
  end

  test "update with an unknown state is not a server error" do
    patch api_v1_shopkeeper_item_tag_url(@item_tag),
      params: {item_tag: {name: "Buy bread", state: "foo"}},
      headers: @shopkeeper.create_new_auth_token

    assert_response :success
    assert @item_tag.reload.idled?
  end

  # destroy
  test "destroy deletes item_tag" do
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
  test "complete completes item_tag" do
    patch complete_api_v1_shopkeeper_item_tag_url(@item_tag), headers: @shopkeeper.create_new_auth_token
    assert_response :success
    assert @item_tag.reload.completed?
  end

  test "complete is a no-op when item_tag is already completed" do
    @item_tag.complete!
    assert @item_tag.reload.completed?

    patch complete_api_v1_shopkeeper_item_tag_url(@item_tag), headers: @shopkeeper.create_new_auth_token
    assert_response :success
    assert @item_tag.reload.completed?
  end

  # idle
  test "idle resets item_tag" do
    @item_tag.complete!
    assert @item_tag.reload.completed?

    patch idle_api_v1_shopkeeper_item_tag_url(@item_tag), headers: @shopkeeper.create_new_auth_token
    assert_response :success
    assert @item_tag.reload.idled?
  end

  private

  def create_item_tags(count)
    ActsAsTenant.with_tenant(@account) do
      count.times { |i| @shop.item_tags.create!(name: "Extra #{i}", account: @account) }
    end
  end
end
