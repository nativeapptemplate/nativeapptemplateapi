require "test_helper"

class ShopkeeperSerializerTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
  end

  test "should serialize basic attributes" do
    serializer = ShopkeeperSerializer.new(@shopkeeper)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert_equal @shopkeeper.email, attributes[:email]
    assert_equal @shopkeeper.name, attributes[:name]
    assert_equal @shopkeeper.time_zone, attributes[:time_zone]
    assert_equal @shopkeeper.locale, attributes[:locale]
  end

  test "should have correct type" do
    serializer = ShopkeeperSerializer.new(@shopkeeper)
    serialized = serializer.serializable_hash

    assert_equal "shopkeeper", serialized[:data][:type].to_s
  end

  test "should have correct id" do
    serializer = ShopkeeperSerializer.new(@shopkeeper)
    serialized = serializer.serializable_hash

    assert_equal @shopkeeper.id, serialized[:data][:id]
  end

  test "should not include sensitive attributes" do
    serializer = ShopkeeperSerializer.new(@shopkeeper)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert_nil attributes[:encrypted_password]
    assert_nil attributes[:uid]
    assert_nil attributes[:tokens]
  end
end
