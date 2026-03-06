require "test_helper"

class ShopkeeperSignInSerializerTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @shopkeeper.token = "test_token"
    @shopkeeper.client = "test_client"
    @shopkeeper.expiry = 123456
    @shopkeeper.account_id = @shopkeeper.personal_account.id
  end

  test "should serialize basic attributes" do
    serializer = ShopkeeperSignInSerializer.new(@shopkeeper)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert_equal @shopkeeper.email, attributes[:email]
    assert_equal @shopkeeper.name, attributes[:name]
    assert_equal @shopkeeper.uid, attributes[:uid]
    assert_equal @shopkeeper.time_zone, attributes[:time_zone]
    assert_equal @shopkeeper.locale, attributes[:locale]
  end

  test "should serialize authentication tokens" do
    serializer = ShopkeeperSignInSerializer.new(@shopkeeper)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert_equal "test_token", attributes[:token]
    assert_equal "test_client", attributes[:client]
    assert_equal 123456.to_s, attributes[:expiry].to_s
  end

  test "should serialize account_id" do
    serializer = ShopkeeperSignInSerializer.new(@shopkeeper)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert_equal @shopkeeper.personal_account.id, attributes[:account_id]
  end

  test "should serialize personal_account_id" do
    serializer = ShopkeeperSignInSerializer.new(@shopkeeper)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert_equal @shopkeeper.personal_account.id, attributes[:personal_account_id]
  end

  test "should serialize account_owner_id" do
    serializer = ShopkeeperSignInSerializer.new(@shopkeeper)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert_equal @shopkeeper.personal_account.owner_id, attributes[:account_owner_id]
  end

  test "should serialize account_name" do
    serializer = ShopkeeperSignInSerializer.new(@shopkeeper)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert_equal @shopkeeper.personal_account.name, attributes[:account_name]
  end

  test "should have correct type" do
    serializer = ShopkeeperSignInSerializer.new(@shopkeeper)
    serialized = serializer.serializable_hash

    assert_equal "shopkeeper_sign_in", serialized[:data][:type].to_s
  end

  test "should have correct id" do
    serializer = ShopkeeperSignInSerializer.new(@shopkeeper)
    serialized = serializer.serializable_hash

    assert_equal @shopkeeper.id, serialized[:data][:id]
  end
end
