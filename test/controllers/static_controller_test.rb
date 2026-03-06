require "test_helper"

class StaticControllerTest < ActionDispatch::IntegrationTest
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first

    ActsAsTenant.with_tenant(@account) do
      @shop = @account.shops.first
      @item_tag = @shop.item_tags.first
    end
  end

  test "should get index" do
    get root_url
    assert_response :success
  end

  test "scan should redirect when type is server" do
    get scan_url, params: {type: "server", item_tag_id: @item_tag.id}
    assert_redirected_to ConfigSettings.site.url
  end

  test "scan_customer should scan tag and redirect when type is customer" do
    ActsAsTenant.with_tenant(@account) do
      assert_equal "unscanned", @item_tag.scan_state

      get scan_customer_url, params: {type: "customer", item_tag_id: @item_tag.id}

      assert_redirected_to display_shop_path(@shop, params: {type: "customer", item_tag_id: @item_tag.id})
      assert_equal "scanned", @item_tag.reload.scan_state
    end
  end
end
