require "test_helper"

class Api::Shopkeeper::ShopPolicyTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
    @shop = @account.shops.first
  end

  test "index? returns true for all users" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    policy = Api::Shopkeeper::ShopPolicy.new(accounts_shopkeeper, @shop)
    assert policy.index?
  end

  test "show? returns true for all users" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    policy = Api::Shopkeeper::ShopPolicy.new(accounts_shopkeeper, @shop)
    assert policy.show?
  end

  test "create? returns true for account owner" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    assert accounts_shopkeeper.account_owner?

    policy = Api::Shopkeeper::ShopPolicy.new(accounts_shopkeeper, @shop)
    assert policy.create?
  end

  test "create? returns false for non-owner" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      admin: true
    )
    assert_not accounts_shopkeeper.account_owner?

    policy = Api::Shopkeeper::ShopPolicy.new(accounts_shopkeeper, @shop)
    assert_not policy.create?
  end

  test "update? returns true for admin" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    accounts_shopkeeper.update!(admin: true)

    policy = Api::Shopkeeper::ShopPolicy.new(accounts_shopkeeper, @shop)
    assert policy.update?
  end

  test "update? returns false for non-admin" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      senior_manager: true
    )

    policy = Api::Shopkeeper::ShopPolicy.new(accounts_shopkeeper, @shop)
    assert_not policy.update?
  end

  test "destroy? delegates to create?" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    policy = Api::Shopkeeper::ShopPolicy.new(accounts_shopkeeper, @shop)
    assert_equal policy.create?, policy.destroy?
  end

  test "reset? returns true for admin" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    accounts_shopkeeper.update!(admin: true)

    policy = Api::Shopkeeper::ShopPolicy.new(accounts_shopkeeper, @shop)
    assert policy.reset?
  end

  test "reset? returns true for senior_manager" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      senior_manager: true
    )

    policy = Api::Shopkeeper::ShopPolicy.new(accounts_shopkeeper, @shop)
    assert policy.reset?
  end

  test "reset? returns true for junior_manager" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      junior_manager: true
    )

    policy = Api::Shopkeeper::ShopPolicy.new(accounts_shopkeeper, @shop)
    assert policy.reset?
  end

  test "reset? returns true for senior_member" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      senior_member: true
    )

    policy = Api::Shopkeeper::ShopPolicy.new(accounts_shopkeeper, @shop)
    assert policy.reset?
  end

  test "reset? returns false for junior_member" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      junior_member: true
    )

    policy = Api::Shopkeeper::ShopPolicy.new(accounts_shopkeeper, @shop)
    assert_not policy.reset?
  end

  test "reset? returns false for guest" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      guest: true
    )

    policy = Api::Shopkeeper::ShopPolicy.new(accounts_shopkeeper, @shop)
    assert_not policy.reset?
  end
end
