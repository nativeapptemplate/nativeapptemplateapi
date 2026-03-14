require "test_helper"

class Api::Shopkeeper::AccountsInvitationPolicyTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
    @accounts_shopkeeper = @account.accounts_shopkeepers.first

    @invitation = AccountsInvitation.create!(
      account: @account,
      name: "Invited User",
      email: "invited@example.com",
      invited_by: @shopkeeper,
      junior_member: true
    )
  end

  test "index? returns true for all users" do
    policy = Api::Shopkeeper::AccountsInvitationPolicy.new(@accounts_shopkeeper, @invitation)
    assert policy.index?
  end

  test "show? returns true for all users" do
    policy = Api::Shopkeeper::AccountsInvitationPolicy.new(@accounts_shopkeeper, @invitation)
    assert policy.show?
  end

  test "create? returns true for admin" do
    @accounts_shopkeeper.update!(admin: true)

    policy = Api::Shopkeeper::AccountsInvitationPolicy.new(@accounts_shopkeeper, @invitation)
    assert policy.create?
  end

  test "create? returns false for non-admin" do
    other_shopkeeper = shopkeepers(:two)
    member = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      junior_member: true
    )

    policy = Api::Shopkeeper::AccountsInvitationPolicy.new(member, @invitation)
    assert_not policy.create?
  end

  test "update? returns true for admin" do
    @accounts_shopkeeper.update!(admin: true)

    policy = Api::Shopkeeper::AccountsInvitationPolicy.new(@accounts_shopkeeper, @invitation)
    assert policy.update?
  end

  test "update? returns false for non-admin" do
    other_shopkeeper = shopkeepers(:two)
    member = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      junior_member: true
    )

    policy = Api::Shopkeeper::AccountsInvitationPolicy.new(member, @invitation)
    assert_not policy.update?
  end

  test "destroy? returns true for admin" do
    @accounts_shopkeeper.update!(admin: true)

    policy = Api::Shopkeeper::AccountsInvitationPolicy.new(@accounts_shopkeeper, @invitation)
    assert policy.destroy?
  end

  test "destroy? returns false for non-admin" do
    other_shopkeeper = shopkeepers(:two)
    member = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      junior_member: true
    )

    policy = Api::Shopkeeper::AccountsInvitationPolicy.new(member, @invitation)
    assert_not policy.destroy?
  end

  test "resend? returns true for admin" do
    @accounts_shopkeeper.update!(admin: true)

    policy = Api::Shopkeeper::AccountsInvitationPolicy.new(@accounts_shopkeeper, @invitation)
    assert policy.resend?
  end

  test "resend? returns false for non-admin" do
    other_shopkeeper = shopkeepers(:two)
    member = AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      junior_member: true
    )

    policy = Api::Shopkeeper::AccountsInvitationPolicy.new(member, @invitation)
    assert_not policy.resend?
  end

  test "show_by_token? returns true for all users" do
    policy = Api::Shopkeeper::AccountsInvitationPolicy.new(@accounts_shopkeeper, @invitation)
    assert policy.show_by_token?
  end

  test "accept? returns true for all users" do
    policy = Api::Shopkeeper::AccountsInvitationPolicy.new(@accounts_shopkeeper, @invitation)
    assert policy.accept?
  end

  test "reject? returns true for all users" do
    policy = Api::Shopkeeper::AccountsInvitationPolicy.new(@accounts_shopkeeper, @invitation)
    assert policy.reject?
  end
end
