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
      assert_equal @item_tag.name, attributes[:name]
      assert_equal @item_tag.description, attributes[:description]
      if @item_tag.position
        assert_equal @item_tag.position, attributes[:position]
      else
        assert_nil attributes[:position]
      end
      assert_equal @item_tag.state, attributes[:state]
      assert_nil attributes[:completed_at]
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
      @item_tag.completed_by = @shopkeeper
      @item_tag.completed_at = Time.current
      @item_tag.complete!

      serializer = ItemTagSerializer.new(@item_tag)
      serialized = serializer.serializable_hash

      attributes = serialized[:data][:attributes]
      assert_equal "completed", attributes[:state]
      assert attributes[:completed_at]
    end
  end
end
