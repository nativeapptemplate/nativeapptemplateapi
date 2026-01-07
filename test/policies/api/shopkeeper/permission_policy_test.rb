require "test_helper"

class Api::Shopkeeper::PermissionPolicyTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
    @accounts_shopkeeper = @account.accounts_shopkeepers.first
    @permission = Permission.first
  end

  test "index? returns true for all users" do
    policy = Api::Shopkeeper::PermissionPolicy.new(@accounts_shopkeeper, @permission)
    assert policy.index?
  end

  test "index? returns true for guest" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      guest: true
    )

    policy = Api::Shopkeeper::PermissionPolicy.new(accounts_shopkeeper, @permission)
    assert policy.index?
  end
end
