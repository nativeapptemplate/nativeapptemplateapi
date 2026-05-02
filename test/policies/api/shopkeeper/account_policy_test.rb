require "test_helper"

class Api::Shopkeeper::AccountPolicyTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
  end

  test "index? returns true for all users" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    policy = Api::Shopkeeper::AccountPolicy.new(accounts_shopkeeper, @account)
    assert policy.index?
  end

  test "show? returns true for all users" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    policy = Api::Shopkeeper::AccountPolicy.new(accounts_shopkeeper, @account)
    assert policy.show?
  end

  test "create? returns true for all users" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    policy = Api::Shopkeeper::AccountPolicy.new(accounts_shopkeeper, @account)
    assert policy.create?
  end

  test "update? returns true for admin" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    accounts_shopkeeper.update!(admin: true)

    policy = Api::Shopkeeper::AccountPolicy.new(accounts_shopkeeper, @account)
    assert policy.update?
  end

  test "update? returns false for non-admin" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      member: true
    )

    policy = Api::Shopkeeper::AccountPolicy.new(accounts_shopkeeper, @account)
    assert_not policy.update?
  end

  test "destroy? returns true for account owner" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    assert accounts_shopkeeper.account_owner?

    policy = Api::Shopkeeper::AccountPolicy.new(accounts_shopkeeper, @account)
    assert policy.destroy?
  end

  test "destroy? returns false for non-owner" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      admin: true
    )

    policy = Api::Shopkeeper::AccountPolicy.new(accounts_shopkeeper, @account)
    assert_not policy.destroy?
  end
end
