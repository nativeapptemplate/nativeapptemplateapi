require "test_helper"

class Api::Shopkeeper::PermissionPolicyTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
    @accounts_shopkeeper = @account.accounts_shopkeepers.first
    @permission = Permission.first
  end

  test "index? returns true for admin" do
    @accounts_shopkeeper.update!(admin: true)
    policy = Api::Shopkeeper::PermissionPolicy.new(@accounts_shopkeeper, @permission)
    assert policy.index?
  end

  test "index? returns true for member" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      member: true
    )

    policy = Api::Shopkeeper::PermissionPolicy.new(accounts_shopkeeper, @permission)
    assert policy.index?
  end
end
