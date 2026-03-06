require "test_helper"

class ShopSerializerTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first

    ActsAsTenant.with_tenant(@account) do
      @shop = @account.shops.first
    end
  end

  test "should serialize basic attributes" do
    ActsAsTenant.with_tenant(@account) do
      serializer = ShopSerializer.new(@shop)
      serialized = serializer.serializable_hash

      attributes = serialized[:data][:attributes]
      assert_equal @shop.name, attributes[:name]
      assert_equal @shop.description, attributes[:description]
      assert_equal @shop.time_zone, attributes[:time_zone]
    end
  end

  test "should serialize item_tags_count" do
    ActsAsTenant.with_tenant(@account) do
      serializer = ShopSerializer.new(@shop)
      serialized = serializer.serializable_hash

      attributes = serialized[:data][:attributes]
      assert_equal @shop.item_tags.size, attributes[:item_tags_count]
    end
  end

  test "should serialize scanned_item_tags_count" do
    ActsAsTenant.with_tenant(@account) do
      item_tag = @shop.item_tags.first
      item_tag.scan_tag!

      serializer = ShopSerializer.new(@shop)
      serialized = serializer.serializable_hash

      attributes = serialized[:data][:attributes]
      assert_equal 1, attributes[:scanned_item_tags_count]
    end
  end

  test "should serialize completed_item_tags_count" do
    ActsAsTenant.with_tenant(@account) do
      item_tag = @shop.item_tags.first
      item_tag.complete_tag!(@shopkeeper)

      serializer = ShopSerializer.new(@shop)
      serialized = serializer.serializable_hash

      attributes = serialized[:data][:attributes]
      assert_equal 1, attributes[:completed_item_tags_count]
    end
  end

  test "should serialize display_shop_server_path" do
    ActsAsTenant.with_tenant(@account) do
      serializer = ShopSerializer.new(@shop)
      serialized = serializer.serializable_hash

      attributes = serialized[:data][:attributes]
      assert_includes attributes[:display_shop_server_path], "/display/shops/"
      assert_includes attributes[:display_shop_server_path], @shop.id
      assert_includes attributes[:display_shop_server_path], "type=server"
    end
  end

  test "should include account relationship" do
    ActsAsTenant.with_tenant(@account) do
      serializer = ShopSerializer.new(@shop)
      serialized = serializer.serializable_hash

      assert serialized[:data][:relationships][:account]
      assert_equal @shop.account_id, serialized[:data][:relationships][:account][:data][:id]
    end
  end

  test "should have correct type" do
    ActsAsTenant.with_tenant(@account) do
      serializer = ShopSerializer.new(@shop)
      serialized = serializer.serializable_hash

      assert_equal "shop", serialized[:data][:type].to_s
    end
  end

  test "should have correct id" do
    ActsAsTenant.with_tenant(@account) do
      serializer = ShopSerializer.new(@shop)
      serialized = serializer.serializable_hash

      assert_equal @shop.id, serialized[:data][:id]
    end
  end
end
