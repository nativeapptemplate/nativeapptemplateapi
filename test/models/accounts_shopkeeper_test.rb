require "test_helper"

class AccountsShopkeeperTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
  end

  test "should be valid with valid attributes" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.new(
      account: @account,
      shopkeeper: other_shopkeeper,
      member: true
    )
    assert accounts_shopkeeper.valid?
  end

  test "should require shopkeeper" do
    accounts_shopkeeper = AccountsShopkeeper.new(account: @account, member: true)
    assert_not accounts_shopkeeper.valid?
    assert_includes accounts_shopkeeper.errors[:shopkeeper], "must exist"
  end

  test "should validate uniqueness of shopkeeper within account" do
    other_shopkeeper = shopkeepers(:two)
    AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      member: true
    )

    duplicate = AccountsShopkeeper.new(
      account: @account,
      shopkeeper: other_shopkeeper,
      admin: true
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:shopkeeper_id], "has already been taken"
  end

  test "should allow same shopkeeper in different accounts" do
    other_shopkeeper = shopkeepers(:two)
    account2 = Account.create!(name: "Account 2", owner: other_shopkeeper)

    AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      member: true
    )

    accounts_shopkeeper2 = AccountsShopkeeper.new(
      account: account2,
      shopkeeper: other_shopkeeper,
      member: true
    )

    assert accounts_shopkeeper2.valid?
  end

  test "should touch account when updated" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      member: true
    )
    old_updated_at = @account.updated_at

    sleep 0.01
    accounts_shopkeeper.update!(admin: true)

    assert @account.reload.updated_at > old_updated_at
  end

  test "account_owner? returns true when shopkeeper is account owner" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    assert accounts_shopkeeper.account_owner?
  end

  test "account_owner? returns false when shopkeeper is not account owner" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      member: true
    )

    assert_not accounts_shopkeeper.account_owner?
  end

  test "owner must be admin validation prevents removing admin from owner" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    assert accounts_shopkeeper.account_owner?
    assert accounts_shopkeeper.admin?

    accounts_shopkeeper.admin = false
    accounts_shopkeeper.member = true

    assert_not accounts_shopkeeper.valid?
    assert_includes accounts_shopkeeper.errors[:admin], I18n.t("activerecord.errors.models.accounts_shopkeeper.attributes.admin.cannot_be_removed")
  end

  test "owner must be admin validation allows admin changes for non-owners" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      admin: true
    )

    accounts_shopkeeper.admin = false
    accounts_shopkeeper.member = true

    assert accounts_shopkeeper.valid?
  end

  test "permissions returns admin permissions for admin role" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    accounts_shopkeeper.update!(admin: true)

    admin_role = Role.find_by(tag: "admin")
    assert_equal admin_role.permissions, accounts_shopkeeper.permissions
  end

  test "permissions returns member permissions for member role" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      member: true
    )

    member_role = Role.find_by(tag: "member")
    assert_equal member_role.permissions, accounts_shopkeeper.permissions
  end

  test "role helper methods work correctly" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      admin: true
    )

    assert accounts_shopkeeper.admin?
    assert_not accounts_shopkeeper.member?
  end

  test "active_roles returns array of active roles" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      admin: true,
      member: true
    )

    active_roles = accounts_shopkeeper.active_roles
    assert_includes active_roles, :admin
    assert_includes active_roles, :member
    assert_equal 2, active_roles.length
  end

  test "role scopes filter correctly" do
    other_shopkeeper = shopkeepers(:two)
    admin_as = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      admin: true
    )

    shopkeeper3 = Shopkeeper.create!(
      name: "Shopkeeper Three",
      email: "three@example.com",
      password: "password",
      current_platform: "ios"
    )
    member_as = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: shopkeeper3,
      member: true
    )

    assert_includes AccountsShopkeeper.admin, admin_as
    assert_not_includes AccountsShopkeeper.admin, member_as

    assert_includes AccountsShopkeeper.member, member_as
    assert_not_includes AccountsShopkeeper.member, admin_as
  end
end
