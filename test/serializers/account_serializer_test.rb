require "test_helper"

class AccountSerializerTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
  end

  test "should serialize basic attributes" do
    serializer = AccountSerializer.new(@account)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert_equal @account.name, attributes[:name]
    assert_equal @account.owner_id, attributes[:owner_id]
    assert_equal @account.personal, attributes[:personal]
  end

  test "should serialize owner_name attribute" do
    serializer = AccountSerializer.new(@account)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert_equal @account.owner.name, attributes[:owner_name]
  end

  # The apps unlock paid features in an account when its owner has the override
  test "should serialize owner_feature_access_state from the owner" do
    attributes = AccountSerializer.new(@account).serializable_hash[:data][:attributes]
    # Fixture one is normal_feature_access
    assert_equal "normal_feature_access", attributes[:owner_feature_access_state]

    @shopkeeper.all_feature_access!
    attributes = AccountSerializer.new(@account.reload).serializable_hash[:data][:attributes]
    assert_equal "all_feature_access", attributes[:owner_feature_access_state]
  end

  test "should serialize owner_feature_access_state of the owner, not the viewing member" do
    owner = shopkeepers(:two) # fixture: all_feature_access
    team = Account.create!(name: "Team", owner: owner, personal: false)
    AccountsShopkeeper.create!(account: team, shopkeeper: @shopkeeper, member: true)

    attributes = AccountSerializer.new(team, params: {current_shopkeeper: @shopkeeper}).serializable_hash[:data][:attributes]
    assert_equal "all_feature_access", attributes[:owner_feature_access_state]
  end

  test "should serialize accounts_shopkeepers_count" do
    AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: shopkeepers(:two),
      member: true
    )

    serializer = AccountSerializer.new(@account)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert_equal 2, attributes[:accounts_shopkeepers_count]
  end

  test "should serialize accounts_invitations_count" do
    AccountsInvitation.create!(
      account: @account,
      name: "Test User",
      email: "test@example.com",
      member: true
    )

    serializer = AccountSerializer.new(@account)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert_equal 1, attributes[:accounts_invitations_count]
  end

  test "should serialize shops_count" do
    serializer = AccountSerializer.new(@account)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert_equal 1, attributes[:shops_count]
  end

  test "should serialize is_admin attribute with current_shopkeeper param" do
    accounts_shopkeeper = @account.accounts_shopkeepers.find_by(shopkeeper: @shopkeeper)
    accounts_shopkeeper.update!(admin: true)

    serializer = AccountSerializer.new(@account, params: {current_shopkeeper: @shopkeeper})
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert attributes[:is_admin]
  end

  test "should serialize is_admin as false for non-admin" do
    other_shopkeeper = shopkeepers(:two)
    AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      member: true
    )

    serializer = AccountSerializer.new(@account, params: {current_shopkeeper: other_shopkeeper})
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert_equal false, attributes[:is_admin]
  end

  test "should include owner relationship" do
    serializer = AccountSerializer.new(@account)
    serialized = serializer.serializable_hash

    assert serialized[:data][:relationships][:owner]
    assert_equal @account.owner_id, serialized[:data][:relationships][:owner][:data][:id]
  end

  test "should include accounts_shopkeepers relationship" do
    serializer = AccountSerializer.new(@account)
    serialized = serializer.serializable_hash

    assert serialized[:data][:relationships][:accounts_shopkeepers]
  end

  test "should include accounts_invitations relationship" do
    serializer = AccountSerializer.new(@account)
    serialized = serializer.serializable_hash

    assert serialized[:data][:relationships][:accounts_invitations]
  end

  test "should have correct type" do
    serializer = AccountSerializer.new(@account)
    serialized = serializer.serializable_hash

    assert_equal "account", serialized[:data][:type].to_s.to_s
  end

  test "should have correct id" do
    serializer = AccountSerializer.new(@account)
    serialized = serializer.serializable_hash

    assert_equal @account.id, serialized[:data][:id]
  end
end
