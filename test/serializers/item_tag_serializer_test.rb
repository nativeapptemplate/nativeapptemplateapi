require "test_helper"

class ItemTagSerializerTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first

    ActsAsTenant.with_tenant(@account) do
      @shop = @account.shops.first
      @item_tag = @shop.item_tags.first
    end
  end

  test "should serialize basic attributes" do
    ActsAsTenant.with_tenant(@account) do
      serializer = ItemTagSerializer.new(@item_tag)
      serialized = serializer.serializable_hash

      attributes = serialized[:data][:attributes]
      assert_equal @item_tag.shop_id, attributes[:shop_id]
      assert_equal @item_tag.queue_number, attributes[:queue_number]
      assert_equal @item_tag.state, attributes[:state]
      assert_equal @item_tag.scan_state, attributes[:scan_state]
      assert_nil attributes[:customer_read_at]
      assert_nil attributes[:completed_at]
      assert_equal @item_tag.already_completed, attributes[:already_completed]
    end
  end

  test "should serialize timestamps" do
    ActsAsTenant.with_tenant(@account) do
      serializer = ItemTagSerializer.new(@item_tag)
      serialized = serializer.serializable_hash

      attributes = serialized[:data][:attributes]
      assert attributes[:created_at]
      assert attributes[:updated_at]
    end
  end

  test "should serialize shop_name attribute" do
    ActsAsTenant.with_tenant(@account) do
      serializer = ItemTagSerializer.new(@item_tag)
      serialized = serializer.serializable_hash

      attributes = serialized[:data][:attributes]
      assert_equal @shop.name, attributes[:shop_name]
    end
  end

  test "should include shop relationship" do
    ActsAsTenant.with_tenant(@account) do
      serializer = ItemTagSerializer.new(@item_tag)
      serialized = serializer.serializable_hash

      assert serialized[:data][:relationships][:shop]
      assert_equal @item_tag.shop_id, serialized[:data][:relationships][:shop][:data][:id]
    end
  end

  test "should have correct type" do
    ActsAsTenant.with_tenant(@account) do
      serializer = ItemTagSerializer.new(@item_tag)
      serialized = serializer.serializable_hash

      assert_equal "item_tag", serialized[:data][:type].to_s
    end
  end

  test "should have correct id" do
    ActsAsTenant.with_tenant(@account) do
      serializer = ItemTagSerializer.new(@item_tag)
      serialized = serializer.serializable_hash

      assert_equal @item_tag.id, serialized[:data][:id]
    end
  end

  test "should serialize completed item tag" do
    ActsAsTenant.with_tenant(@account) do
      @item_tag.complete_tag!(@shopkeeper)

      serializer = ItemTagSerializer.new(@item_tag)
      serialized = serializer.serializable_hash

      attributes = serialized[:data][:attributes]
      assert_equal "completed", attributes[:state]
      assert attributes[:completed_at]
      assert_not_nil attributes[:already_completed]
    end
  end

  test "should serialize scanned item tag" do
    ActsAsTenant.with_tenant(@account) do
      @item_tag.scan_tag!

      serializer = ItemTagSerializer.new(@item_tag)
      serialized = serializer.serializable_hash

      attributes = serialized[:data][:attributes]
      assert_equal "scanned", attributes[:scan_state]
    end
  end
end
