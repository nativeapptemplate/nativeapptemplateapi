require "test_helper"

class Api::Shopkeeper::ShopPolicyTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
    @shop = @account.shops.first
  end

  def admin_accounts_shopkeeper
    @account.accounts_shopkeepers.first.tap { |as| as.update!(admin: true) }
  end

  def member_accounts_shopkeeper
    other_shopkeeper = shopkeepers(:two)
    AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      member: true
    )
  end

  test "index? returns true for admin" do
    policy = Api::Shopkeeper::ShopPolicy.new(admin_accounts_shopkeeper, @shop)
    assert policy.index?
  end

  test "index? returns true for member" do
    policy = Api::Shopkeeper::ShopPolicy.new(member_accounts_shopkeeper, @shop)
    assert policy.index?
  end

  test "show? returns true for admin" do
    policy = Api::Shopkeeper::ShopPolicy.new(admin_accounts_shopkeeper, @shop)
    assert policy.show?
  end

  test "show? returns true for member" do
    policy = Api::Shopkeeper::ShopPolicy.new(member_accounts_shopkeeper, @shop)
    assert policy.show?
  end

  test "create? returns true for admin" do
    policy = Api::Shopkeeper::ShopPolicy.new(admin_accounts_shopkeeper, @shop)
    assert policy.create?
  end

  test "create? returns true for member" do
    policy = Api::Shopkeeper::ShopPolicy.new(member_accounts_shopkeeper, @shop)
    assert policy.create?
  end

  test "update? returns true for admin" do
    policy = Api::Shopkeeper::ShopPolicy.new(admin_accounts_shopkeeper, @shop)
    assert policy.update?
  end

  test "update? returns true for member" do
    policy = Api::Shopkeeper::ShopPolicy.new(member_accounts_shopkeeper, @shop)
    assert policy.update?
  end

  test "destroy? returns true for admin" do
    policy = Api::Shopkeeper::ShopPolicy.new(admin_accounts_shopkeeper, @shop)
    assert policy.destroy?
  end

  test "destroy? returns true for member" do
    policy = Api::Shopkeeper::ShopPolicy.new(member_accounts_shopkeeper, @shop)
    assert policy.destroy?
  end

  # Bug: destroy? checked the role name, so taking delete_shops away from member
  # in roles_permissions hid the button in the apps but the API still deleted
  test "destroy? follows roles_permissions, not the role name" do
    member_role = Role.find_by!(tag: "member")
    member_role.roles_permissions.joins(:permission).where(permissions: {tag: "delete_shops"}).destroy_all

    policy = Api::Shopkeeper::ShopPolicy.new(member_accounts_shopkeeper, @shop)

    assert_not policy.destroy?
    assert policy.update?
  end
end
