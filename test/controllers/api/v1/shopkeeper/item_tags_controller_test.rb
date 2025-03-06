require "test_helper"

class Api::V1::Shopkeeper::ItemTagsControllerTest < ActionDispatch::IntegrationTest
  test "returns item_tags" do
    shopkeeper = shopkeepers(:one)
    shopkeeper.create_default_account
    shop = shopkeeper.created_shops.first
    item_tag = shop.item_tags.first

    get api_v1_shopkeeper_shop_item_tags_url(shop), headers: shopkeeper.create_new_auth_token
    assert_response :success
    assert_includes response.parsed_body["data"].map { |t| t["attributes"]["queue_number"] }, item_tag.queue_number
  end

  test "returns an item_tag detail" do
    shopkeeper = shopkeepers(:one)
    shopkeeper.create_default_account
    shop = shopkeeper.created_shops.first
    item_tag = shop.item_tags.first

    get api_v1_shopkeeper_item_tag_url(item_tag), headers: shopkeeper.create_new_auth_token
    assert_response :success
    assert_equal response.parsed_body["data"]["attributes"]["queue_number"], item_tag.queue_number
  end

  test "cpmpletes an item_tag" do
    shopkeeper = shopkeepers(:one)
    shopkeeper.create_default_account
    shop = shopkeeper.created_shops.first
    item_tag = shop.item_tags.first

    patch complete_api_v1_shopkeeper_item_tag_url(item_tag), headers: shopkeeper.create_new_auth_token
    assert_response :success
    assert_equal true, item_tag.reload.completed?
  end

  test "resets an item_tag" do
    shopkeeper = shopkeepers(:one)
    shopkeeper.create_default_account
    shop = shopkeeper.created_shops.first
    item_tag = shop.item_tags.first
    item_tag.complete!

    assert_equal true, item_tag.reload.completed?

    patch reset_api_v1_shopkeeper_item_tag_url(item_tag), headers: shopkeeper.create_new_auth_token
    assert_response :success
    assert_equal true, item_tag.reload.idled?
  end
end
