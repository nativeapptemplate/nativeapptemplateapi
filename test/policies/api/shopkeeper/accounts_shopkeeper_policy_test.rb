require "test_helper"

class Api::Shopkeeper::AccountsShopkeeperPolicyTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first

    @team_account = Account.create!(name: "Team Account", owner: @shopkeeper, personal: false)
    @team_accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @team_account,
      shopkeeper: @shopkeeper,
      admin: true
    )
  end

  test "index? returns true for all users" do
    policy = Api::Shopkeeper::AccountsShopkeeperPolicy.new(@team_accounts_shopkeeper, @team_accounts_shopkeeper)
    assert policy.index?
  end

  test "show? returns true for all users" do
    other_shopkeeper = shopkeepers(:two)
    member = AccountsShopkeeper.create!(
      account: @team_account,
      shopkeeper: other_shopkeeper,
      member: true
    )

    policy = Api::Shopkeeper::AccountsShopkeeperPolicy.new(member, @team_accounts_shopkeeper)
    assert policy.show?
  end

  test "update? returns true for admin" do
    policy = Api::Shopkeeper::AccountsShopkeeperPolicy.new(@team_accounts_shopkeeper, @team_accounts_shopkeeper)
    assert policy.update?
  end

  test "update? returns false for non-admin" do
    other_shopkeeper = shopkeepers(:two)
    member = AccountsShopkeeper.create!(
      account: @team_account,
      shopkeeper: other_shopkeeper,
      member: true
    )

    policy = Api::Shopkeeper::AccountsShopkeeperPolicy.new(member, @team_accounts_shopkeeper)
    assert_not policy.update?
  end

  test "destroy? returns true for admin" do
    policy = Api::Shopkeeper::AccountsShopkeeperPolicy.new(@team_accounts_shopkeeper, @team_accounts_shopkeeper)
    assert policy.destroy?
  end

  test "destroy? returns false for non-admin" do
    other_shopkeeper = shopkeepers(:two)
    member = AccountsShopkeeper.create!(
      account: @team_account,
      shopkeeper: other_shopkeeper,
      member: true
    )

    policy = Api::Shopkeeper::AccountsShopkeeperPolicy.new(member, @team_accounts_shopkeeper)
    assert_not policy.destroy?
  end
end
