require "test_helper"

class Api::V1::Shopkeeper::BaseControllerTest < ActionDispatch::IntegrationTest
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
    @shop = @account.shops.first
  end

  test "render_validation_error returns 422 with error messages" do
    item_tag = @shop.item_tags.first

    # Try to create a duplicate queue_number to trigger validation error
    post api_v1_shopkeeper_shop_item_tags_url(@shop),
      params: {item_tag: {queue_number: item_tag.queue_number}},
      headers: @shopkeeper.create_new_auth_token

    assert_response :unprocessable_entity
    assert_equal 422, response.parsed_body["code"]
    assert_not_nil response.parsed_body["error_message"]
  end

  test "render_error returns custom error code and message for not found" do
    get api_v1_shopkeeper_item_tag_url(id: "nonexistent-uuid"),
      headers: @shopkeeper.create_new_auth_token

    assert_response :not_found
    assert_equal 404, response.parsed_body["code"]
    assert_equal I18n.t("api.shopkeeper.item_tags.not_found"), response.parsed_body["error_message"]
  end
end
