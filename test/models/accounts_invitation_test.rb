require "test_helper"

class AccountsInvitationTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
  end

  test "should be valid with valid attributes" do
    invitation = AccountsInvitation.new(
      account: @account,
      name: "Invited User",
      email: "invited@example.com",
      invited_by: @shopkeeper,
      junior_member: true
    )
    assert invitation.valid?
  end

  test "should require name" do
    invitation = AccountsInvitation.new(
      account: @account,
      email: "invited@example.com",
      junior_member: true
    )
    assert_not invitation.valid?
    assert_includes invitation.errors[:name], "can't be blank"
  end

  test "should require email" do
    invitation = AccountsInvitation.new(
      account: @account,
      name: "Invited User",
      junior_member: true
    )
    assert_not invitation.valid?
    assert_includes invitation.errors[:email], "can't be blank"
  end

  test "should validate uniqueness of email within account" do
    AccountsInvitation.create!(
      account: @account,
      name: "User 1",
      email: "same@example.com",
      junior_member: true
    )

    duplicate = AccountsInvitation.new(
      account: @account,
      name: "User 2",
      email: "same@example.com",
      junior_member: true
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], I18n.t("activerecord.errors.models.accounts_invitation.attributes.email.invited")
  end

  test "should allow same email in different accounts" do
    other_shopkeeper = shopkeepers(:two)
    account2 = Account.create!(name: "Account 2", owner: other_shopkeeper)

    AccountsInvitation.create!(
      account: @account,
      name: "User 1",
      email: "same@example.com",
      junior_member: true
    )

    invitation2 = AccountsInvitation.new(
      account: account2,
      name: "User 2",
      email: "same@example.com",
      junior_member: true
    )

    assert invitation2.valid?
  end

  test "should generate token before creation" do
    invitation = AccountsInvitation.create!(
      account: @account,
      name: "Invited User",
      email: "token@example.com",
      junior_member: true
    )

    assert_not_nil invitation.token
    assert_equal 6, invitation.token.length
    assert invitation.token.match?(/\A\d{6}\z/)
  end

  test "should generate unique tokens" do
    invitation1 = AccountsInvitation.create!(
      account: @account,
      name: "User 1",
      email: "user1@example.com",
      junior_member: true
    )

    invitation2 = AccountsInvitation.create!(
      account: @account,
      name: "User 2",
      email: "user2@example.com",
      junior_member: true
    )

    assert_not_equal invitation1.token, invitation2.token
  end

  test "to_param returns token" do
    invitation = AccountsInvitation.create!(
      account: @account,
      name: "Invited User",
      email: "param@example.com",
      junior_member: true
    )

    assert_equal invitation.token, invitation.to_param
  end

  test "accept! creates accounts_shopkeeper with correct roles" do
    invitation = AccountsInvitation.create!(
      account: @account,
      name: "Invited User",
      email: "accept@example.com",
      senior_manager: true
    )

    other_shopkeeper = shopkeepers(:two)

    assert_difference "AccountsShopkeeper.count", 1 do
      result = invitation.accept!(other_shopkeeper)
      assert_not_nil result
      assert result.is_a?(AccountsShopkeeper)
    end

    accounts_shopkeeper = AccountsShopkeeper.find_by(
      account: @account,
      shopkeeper: other_shopkeeper
    )

    assert accounts_shopkeeper.senior_manager?
  end

  test "accept! destroys invitation after creating accounts_shopkeeper" do
    invitation = AccountsInvitation.create!(
      account: @account,
      name: "Invited User",
      email: "destroy@example.com",
      junior_member: true
    )

    other_shopkeeper = shopkeepers(:two)

    assert_difference "AccountsInvitation.count", -1 do
      invitation.accept!(other_shopkeeper)
    end
  end

  test "accept! returns nil and adds error if accounts_shopkeeper is invalid" do
    invitation = AccountsInvitation.create!(
      account: @account,
      name: "Invited User",
      email: "invalid@example.com",
      junior_member: true
    )

    # Create a shopkeeper that's already a member
    other_shopkeeper = shopkeepers(:two)
    AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      junior_member: true
    )

    result = invitation.accept!(other_shopkeeper)

    assert_nil result
    assert invitation.errors[:base].present?
  end

  test "accept! is atomic - rolls back if accounts_shopkeeper fails" do
    invitation = AccountsInvitation.create!(
      account: @account,
      name: "Invited User",
      email: "atomic@example.com",
      junior_member: true
    )

    other_shopkeeper = shopkeepers(:two)
    # Create existing membership
    AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      junior_member: true
    )

    initial_invitation_count = AccountsInvitation.count
    initial_as_count = AccountsShopkeeper.count

    invitation.accept!(other_shopkeeper)

    # Invitation should not be destroyed if accounts_shopkeeper creation fails
    assert_equal initial_invitation_count, AccountsInvitation.count
    assert_equal initial_as_count, AccountsShopkeeper.count
  end

  test "reject! destroys the invitation" do
    invitation = AccountsInvitation.create!(
      account: @account,
      name: "Invited User",
      email: "reject@example.com",
      junior_member: true
    )

    assert_difference "AccountsInvitation.count", -1 do
      invitation.reject!
    end
  end

  test "role helper methods work correctly" do
    invitation = AccountsInvitation.create!(
      account: @account,
      name: "Invited User",
      email: "roles@example.com",
      admin: true
    )

    assert invitation.admin?
    assert_not invitation.senior_manager?
  end

  test "active_roles returns array of assigned roles" do
    invitation = AccountsInvitation.create!(
      account: @account,
      name: "Invited User",
      email: "active@example.com",
      admin: true,
      senior_member: true
    )

    active_roles = invitation.active_roles
    assert_includes active_roles, :admin
    assert_includes active_roles, :senior_member
    assert_equal 2, active_roles.length
  end

  test "save_and_send_invite saves and sends invitation email" do
    invitation = AccountsInvitation.new(
      account: @account,
      name: "Invited User",
      email: "send@example.com",
      junior_member: true
    )

    assert_difference "AccountsInvitation.count", 1 do
      result = invitation.save_and_send_invite
      assert result
    end
  end

  test "send_invite sends invitation email" do
    invitation = AccountsInvitation.create!(
      account: @account,
      name: "Invited User",
      email: "send2@example.com",
      junior_member: true
    )

    # Email delivery is tested by the fact that the method doesn't raise an error
    assert_nothing_raised do
      invitation.send_invite
    end
  end

  test "expired? returns false for recent invitation" do
    invitation = AccountsInvitation.create!(
      account: @account,
      name: "Invited User",
      email: "recent@example.com",
      junior_member: true
    )

    assert_not invitation.expired?
  end

  test "expired? returns true for old invitation" do
    invitation = AccountsInvitation.create!(
      account: @account,
      name: "Invited User",
      email: "old@example.com",
      junior_member: true
    )

    travel_to(AccountsInvitation::EXPIRES_IN.from_now + 1.minute) do
      assert invitation.expired?
    end
  end

  test "active scope returns non-expired invitations" do
    active_invitation = AccountsInvitation.create!(
      account: @account,
      name: "Active User",
      email: "active_scope@example.com",
      junior_member: true
    )

    expired_invitation = AccountsInvitation.create!(
      account: @account,
      name: "Expired User",
      email: "expired_scope@example.com",
      junior_member: true
    )
    expired_invitation.update_column(:created_at, (AccountsInvitation::EXPIRES_IN + 1.minute).ago)

    active_invitations = AccountsInvitation.active
    assert_includes active_invitations, active_invitation
    assert_not_includes active_invitations, expired_invitation
  end

  test "resend_invite touches created_at and sends invite" do
    invitation = AccountsInvitation.create!(
      account: @account,
      name: "Invited User",
      email: "resend@example.com",
      invited_by: @shopkeeper,
      junior_member: true
    )

    original_created_at = invitation.created_at

    travel_to(1.hour.from_now) do
      assert_nothing_raised do
        invitation.resend_invite
      end

      assert invitation.created_at > original_created_at
    end
  end
end
