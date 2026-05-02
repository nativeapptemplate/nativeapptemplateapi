require "test_helper"

class Api::Shopkeeper::ItemTagPolicyTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
    @shop = @account.shops.first
    @item_tag = @shop.item_tags.first
  end

  test "index? returns true for admin" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    accounts_shopkeeper.update!(admin: true)
    policy = Api::Shopkeeper::ItemTagPolicy.new(accounts_shopkeeper, @item_tag)
    assert policy.index?
  end

  test "index? returns true for member" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      member: true
    )
    policy = Api::Shopkeeper::ItemTagPolicy.new(accounts_shopkeeper, @item_tag)
    assert policy.index?
  end

  test "show? returns true for admin" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    accounts_shopkeeper.update!(admin: true)
    policy = Api::Shopkeeper::ItemTagPolicy.new(accounts_shopkeeper, @item_tag)
    assert policy.show?
  end

  test "show? returns true for member" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      member: true
    )
    policy = Api::Shopkeeper::ItemTagPolicy.new(accounts_shopkeeper, @item_tag)
    assert policy.show?
  end

  test "create? returns true for admin" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    accounts_shopkeeper.update!(admin: true)
    policy = Api::Shopkeeper::ItemTagPolicy.new(accounts_shopkeeper, @item_tag)
    assert policy.create?
  end

  test "create? returns true for member" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      member: true
    )
    policy = Api::Shopkeeper::ItemTagPolicy.new(accounts_shopkeeper, @item_tag)
    assert policy.create?
  end

  test "update? delegates to create?" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    policy = Api::Shopkeeper::ItemTagPolicy.new(accounts_shopkeeper, @item_tag)
    assert_equal policy.create?, policy.update?
  end

  test "destroy? delegates to create?" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    policy = Api::Shopkeeper::ItemTagPolicy.new(accounts_shopkeeper, @item_tag)
    assert_equal policy.create?, policy.destroy?
  end

  test "complete? returns true for admin" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    accounts_shopkeeper.update!(admin: true)
    policy = Api::Shopkeeper::ItemTagPolicy.new(accounts_shopkeeper, @item_tag)
    assert policy.complete?
  end

  test "complete? returns true for member" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      member: true
    )
    policy = Api::Shopkeeper::ItemTagPolicy.new(accounts_shopkeeper, @item_tag)
    assert policy.complete?
  end

  test "idle? delegates to create?" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    policy = Api::Shopkeeper::ItemTagPolicy.new(accounts_shopkeeper, @item_tag)
    assert_equal policy.create?, policy.idle?
  end
end
