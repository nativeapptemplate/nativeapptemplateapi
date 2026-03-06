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
      junior_member: true
    )
    assert accounts_shopkeeper.valid?
  end

  test "should require shopkeeper" do
    accounts_shopkeeper = AccountsShopkeeper.new(account: @account, junior_member: true)
    assert_not accounts_shopkeeper.valid?
    assert_includes accounts_shopkeeper.errors[:shopkeeper], "must exist"
  end

  test "should validate uniqueness of shopkeeper within account" do
    other_shopkeeper = shopkeepers(:two)
    AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      junior_member: true
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
      junior_member: true
    )

    accounts_shopkeeper2 = AccountsShopkeeper.new(
      account: account2,
      shopkeeper: other_shopkeeper,
      junior_member: true
    )

    assert accounts_shopkeeper2.valid?
  end

  test "should touch account when updated" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    old_updated_at = @account.updated_at

    sleep 0.01
    accounts_shopkeeper.update!(senior_member: true)

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
      junior_member: true
    )

    assert_not accounts_shopkeeper.account_owner?
  end

  test "owner must be admin validation prevents removing admin from owner" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    assert accounts_shopkeeper.account_owner?
    assert accounts_shopkeeper.admin?

    accounts_shopkeeper.admin = false
    accounts_shopkeeper.junior_member = true

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
    accounts_shopkeeper.junior_member = true

    assert accounts_shopkeeper.valid?
  end

  test "permissions returns admin permissions for admin role" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first
    accounts_shopkeeper.update!(admin: true)

    admin_role = Role.find_by(tag: "admin")
    assert_equal admin_role.permissions, accounts_shopkeeper.permissions
  end

  test "permissions returns senior_manager permissions for senior_manager role" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      senior_manager: true
    )

    senior_manager_role = Role.find_by(tag: "senior_manager")
    assert_equal senior_manager_role.permissions, accounts_shopkeeper.permissions
  end

  test "permissions returns junior_manager permissions for junior_manager role" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      junior_manager: true
    )

    junior_manager_role = Role.find_by(tag: "junior_manager")
    assert_equal junior_manager_role.permissions, accounts_shopkeeper.permissions
  end

  test "permissions returns senior_member permissions for senior_member role" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      senior_member: true
    )

    senior_member_role = Role.find_by(tag: "senior_member")
    assert_equal senior_member_role.permissions, accounts_shopkeeper.permissions
  end

  test "permissions returns junior_member permissions for junior_member role" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      junior_member: true
    )

    junior_member_role = Role.find_by(tag: "junior_member")
    assert_equal junior_member_role.permissions, accounts_shopkeeper.permissions
  end

  test "permissions returns guest permissions for guest role" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      guest: true
    )

    guest_role = Role.find_by(tag: "guest")
    assert_equal guest_role.permissions, accounts_shopkeeper.permissions
  end

  test "role helper methods work correctly" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      admin: true
    )

    assert accounts_shopkeeper.admin?
    assert_not accounts_shopkeeper.senior_manager?
    assert_not accounts_shopkeeper.junior_manager?
    assert_not accounts_shopkeeper.senior_member?
    assert_not accounts_shopkeeper.junior_member?
    assert_not accounts_shopkeeper.guest?
  end

  test "active_roles returns array of active roles" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      admin: true,
      senior_member: true
    )

    active_roles = accounts_shopkeeper.active_roles
    assert_includes active_roles, :admin
    assert_includes active_roles, :senior_member
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
      junior_member: true
    )

    assert_includes AccountsShopkeeper.admin, admin_as
    assert_not_includes AccountsShopkeeper.admin, member_as

    assert_includes AccountsShopkeeper.junior_member, member_as
    assert_not_includes AccountsShopkeeper.junior_member, admin_as
  end
end
