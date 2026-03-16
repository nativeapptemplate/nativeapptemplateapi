require "test_helper"

class ShopkeeperTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    shopkeeper = Shopkeeper.new(
      name: "Test User",
      email: "test@example.com",
      password: "password123",
      current_platform: "ios",
      confirmed_privacy_version: "1.0.0",
      confirmed_terms_version: "1.0.0"
    )
    assert shopkeeper.valid?
  end

  test "should require name" do
    shopkeeper = Shopkeeper.new(
      email: "test@example.com",
      password: "password123",
      current_platform: "ios"
    )
    assert_not shopkeeper.valid?
    assert_includes shopkeeper.errors[:name], "can't be blank"
  end

  test "should require email" do
    shopkeeper = Shopkeeper.new(
      name: "Test User",
      password: "password123",
      current_platform: "ios"
    )
    assert_not shopkeeper.valid?
    assert_includes shopkeeper.errors[:email], "can't be blank"
  end

  test "should require current_platform" do
    shopkeeper = Shopkeeper.new(
      name: "Test User",
      email: "test@example.com",
      password: "password123"
    )
    assert_not shopkeeper.valid?
    assert shopkeeper.errors[:current_platform].present?
  end

  test "should validate current_platform inclusion" do
    shopkeeper = Shopkeeper.new(
      name: "Test User",
      email: "test@example.com",
      password: "password123",
      current_platform: "windows"
    )
    assert_not shopkeeper.valid?
    assert_includes shopkeeper.errors[:current_platform], "is not included in the list"
  end

  test "should accept ios as current_platform" do
    shopkeeper = shopkeepers(:one)
    shopkeeper.current_platform = "ios"
    assert shopkeeper.valid?
  end

  test "should accept android as current_platform" do
    shopkeeper = shopkeepers(:one)
    shopkeeper.current_platform = "android"
    assert shopkeeper.valid?
  end

  test "should have many shops through accounts" do
    shopkeeper = shopkeepers(:one)
    shopkeeper.create_default_account
    account = shopkeeper.accounts.first

    assert_equal account.shops, shopkeeper.shops
  end

  test "should have many item_tags through shops" do
    shopkeeper = shopkeepers(:one)
    shopkeeper.create_default_account
    account = shopkeeper.accounts.first
    shop = account.shops.first

    ActsAsTenant.with_tenant(account) do
      assert_equal shop.item_tags.to_a, shopkeeper.item_tags.to_a
    end
  end

  test "should have many created_shops" do
    shopkeeper = shopkeepers(:one)
    shopkeeper.create_default_account
    shop = shopkeeper.created_shops.first

    assert_equal shopkeeper, shop.created_by
  end

  test "create_default_account creates personal account" do
    shopkeeper = Shopkeeper.create!(
      name: "Test User",
      email: "newuser@example.com",
      password: "password123",
      current_platform: "ios",
      confirmed_privacy_version: "1.0.0",
      confirmed_terms_version: "1.0.0"
    )

    assert_equal 1, shopkeeper.accounts.count
    assert shopkeeper.personal_account.present?
    assert shopkeeper.personal_account.personal?
    assert_equal shopkeeper.name, shopkeeper.personal_account.name
  end

  test "create_default_account creates accounts_shopkeeper with admin role" do
    shopkeeper = Shopkeeper.create!(
      name: "Test User",
      email: "newuser2@example.com",
      password: "password123",
      current_platform: "ios",
      confirmed_privacy_version: "1.0.0",
      confirmed_terms_version: "1.0.0"
    )

    accounts_shopkeeper = shopkeeper.accounts_shopkeepers.first
    assert accounts_shopkeeper.admin?
  end

  test "create_default_account does not create account if name is blank" do
    # Skip validations to create shopkeeper without name
    shopkeeper = Shopkeeper.new(
      email: "noname@example.com",
      password: "password123",
      current_platform: "ios"
    )
    shopkeeper.save(validate: false)

    assert_equal 0, shopkeeper.accounts.count
  end

  test "create_default_account returns existing account if already present" do
    shopkeeper = shopkeepers(:one)
    shopkeeper.create_default_account
    first_account = shopkeeper.accounts.first

    result = shopkeeper.create_default_account

    assert_equal first_account, result
    assert_equal 1, shopkeeper.accounts.count
  end

  test "sync_personal_account_name updates personal account name when shopkeeper name changes" do
    shopkeeper = shopkeepers(:one)
    shopkeeper.create_default_account
    personal_account = shopkeeper.personal_account

    shopkeeper.update!(name: "Updated Name")

    assert_equal "Updated Name", personal_account.reload.name
  end

  test "sync_personal_account_name creates personal account if missing when name is updated" do
    # Create shopkeeper without personal account
    shopkeeper = Shopkeeper.new(
      email: "test3@example.com",
      password: "password123",
      current_platform: "ios"
    )
    shopkeeper.save(validate: false)

    assert_nil shopkeeper.personal_account

    shopkeeper.update!(name: "New Name")

    assert_not_nil shopkeeper.reload.personal_account
    assert_equal "New Name", shopkeeper.personal_account.name
  end

  test "should nullify accounts_invitations invited_by on destroy" do
    shopkeeper = shopkeepers(:one)
    other_shopkeeper = shopkeepers(:two)
    other_shopkeeper.create_default_account
    account = other_shopkeeper.accounts.first

    # Create invitation invited by shopkeeper on another account
    invitation = AccountsInvitation.create!(
      account: account,
      invited_by: shopkeeper,
      name: "Invited User",
      email: "invited@example.com",
      junior_member: true
    )

    shopkeeper.destroy

    # Invitation should still exist (on other_shopkeeper's account)
    # but invited_by_id should be nullified
    assert AccountsInvitation.exists?(invitation.id)
    assert_nil invitation.reload.invited_by_id
  end

  test "should destroy associated accounts_shopkeepers" do
    shopkeeper = shopkeepers(:one)
    shopkeeper.create_default_account

    assert_difference "AccountsShopkeeper.count", -1 do
      shopkeeper.destroy
    end
  end

  test "should destroy associated owned_accounts" do
    shopkeeper = shopkeepers(:one)
    shopkeeper.create_default_account

    assert_difference "Account.count", -1 do
      shopkeeper.destroy
    end
  end
end
