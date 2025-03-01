require "test_helper"

class ShopsTest < ActionDispatch::IntegrationTest
  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @shop = @shopkeeper.created_shops.first
    @item_tag = @shop.item_tags.first
  end

  test "can show a number tags web page" do
    patch complete_api_v1_shopkeeper_item_tag_url(@item_tag), headers: @shopkeeper.create_new_auth_token
    assert_response :success
    assert_equal true, @item_tag.reload.completed?

    get display_shop_url(@shop.reload), params: {type: "server"}, headers: {HTTP_USER_AGENT: "Turbo Native iOS"}
    assert_response :success

    assert_equal true, @item_tag.reload.completed?
    # Not work because using turbo.
    # assert_select "span", text: @item_tag.queue_number, count: 1
    assert_select "p", text: /Completed!/, count: 1
  end
end
