require "test_helper"

class Display::ShopsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first

    ActsAsTenant.with_tenant(@account) do
      @shop = @account.shops.first
    end
  end

  test "should show shop" do
    get display_shop_url(@shop)
    assert_response :success
  end

  test "should show shop with type param" do
    get display_shop_url(@shop), params: {type: "customer"}
    assert_response :success
  end

  test "should show shop with item_tag_id param" do
    ActsAsTenant.with_tenant(@account) do
      item_tag = @shop.item_tags.first
      get display_shop_url(@shop), params: {type: "customer", item_tag_id: item_tag.id}
      assert_response :success
    end
  end

  test "should return not found for invalid shop" do
    get display_shop_url(id: "invalid-id")
    assert_response :not_found
  end
end
