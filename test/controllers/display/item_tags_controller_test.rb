require "test_helper"

class Display::ItemTagsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first

    ActsAsTenant.with_tenant(@account) do
      @shop = @account.shops.first

      # Create some completed item tags for testing
      @item_tag1 = @shop.item_tags.first
      @item_tag1.complete_tag!(@shopkeeper)

      @item_tag2 = @shop.item_tags.create!(
        queue_number: "B001",
        created_by: @shopkeeper
      )
      @item_tag2.complete_tag!(@shopkeeper)
    end
  end

  test "should get completings" do
    get completings_display_shop_item_tags_url(@shop)
    assert_response :success
  end

  test "should get completings with type param" do
    get completings_display_shop_item_tags_url(@shop), params: {type: "customer"}
    assert_response :success
  end

  test "should get completings with item_tag_id param" do
    get completings_display_shop_item_tags_url(@shop), params: {type: "customer", item_tag_id: @item_tag1.id}
    assert_response :success
  end

  test "should paginate completed item tags" do
    get completings_display_shop_item_tags_url(@shop)
    assert_response :success
  end

  test "should only show completed item tags" do
    ActsAsTenant.with_tenant(@account) do
      @shop.item_tags.create!(
        queue_number: "C001",
        created_by: @shopkeeper
      )

      get completings_display_shop_item_tags_url(@shop)
      assert_response :success
    end
  end

  test "should return not found for invalid shop" do
    get completings_display_shop_item_tags_url(shop_id: "invalid-id")
    assert_response :not_found
  end
end
