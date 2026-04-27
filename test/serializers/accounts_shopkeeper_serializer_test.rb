require "test_helper"

class AccountsShopkeeperSerializerTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first

    @accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: shopkeepers(:two),
      member: true
    )
  end

  test "should serialize basic attributes" do
    serializer = AccountsShopkeeperSerializer.new(@accounts_shopkeeper)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert_equal @accounts_shopkeeper.account_id, attributes[:account_id]
    assert_equal @accounts_shopkeeper.shopkeeper_id, attributes[:shopkeeper_id]
  end

  test "should serialize all role attributes" do
    serializer = AccountsShopkeeperSerializer.new(@accounts_shopkeeper)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    AccountsShopkeeper::ROLES.each do |role|
      assert attributes.key?(role)
    end
  end

  test "should serialize member role" do
    serializer = AccountsShopkeeperSerializer.new(@accounts_shopkeeper)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert attributes[:member]
    assert_not attributes[:admin]
  end

  test "should serialize admin role" do
    admin_as = @account.accounts_shopkeepers.find_by(shopkeeper: @shopkeeper)
    admin_as.update!(admin: true)

    serializer = AccountsShopkeeperSerializer.new(admin_as)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert attributes[:admin]
  end

  test "should include account relationship" do
    serializer = AccountsShopkeeperSerializer.new(@accounts_shopkeeper)
    serialized = serializer.serializable_hash

    assert serialized[:data][:relationships][:account]
    assert_equal @accounts_shopkeeper.account_id, serialized[:data][:relationships][:account][:data][:id]
  end

  test "should include shopkeeper relationship" do
    serializer = AccountsShopkeeperSerializer.new(@accounts_shopkeeper)
    serialized = serializer.serializable_hash

    assert serialized[:data][:relationships][:shopkeeper]
    assert_equal @accounts_shopkeeper.shopkeeper_id, serialized[:data][:relationships][:shopkeeper][:data][:id]
  end

  test "should have correct type" do
    serializer = AccountsShopkeeperSerializer.new(@accounts_shopkeeper)
    serialized = serializer.serializable_hash

    assert_equal "accounts_shopkeeper", serialized[:data][:type].to_s
  end

  test "should have correct id" do
    serializer = AccountsShopkeeperSerializer.new(@accounts_shopkeeper)
    serialized = serializer.serializable_hash

    assert_equal @accounts_shopkeeper.id, serialized[:data][:id]
  end
end
