require "test_helper"

class AccountsInvitationSerializerTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first

    @invitation = AccountsInvitation.create!(
      account: @account,
      name: "Invited User",
      email: "invited@example.com",
      invited_by: @shopkeeper,
      admin: true
    )
  end

  test "should serialize basic attributes" do
    serializer = AccountsInvitationSerializer.new(@invitation)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert_equal @invitation.account_id, attributes[:account_id]
    assert_equal @invitation.invited_by_id, attributes[:invited_by_id]
    assert_equal @invitation.name, attributes[:name]
    assert_equal @invitation.token, attributes[:token]
    assert_equal @invitation.email, attributes[:email]
  end

  test "should serialize all role attributes" do
    serializer = AccountsInvitationSerializer.new(@invitation)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    AccountsShopkeeper::ROLES.each do |role|
      assert attributes.key?(role)
    end
  end

  test "should serialize admin role" do
    serializer = AccountsInvitationSerializer.new(@invitation)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert attributes[:admin]
  end

  test "should serialize member role" do
    invitation = AccountsInvitation.create!(
      account: @account,
      name: "Member User",
      email: "member@example.com",
      member: true
    )

    serializer = AccountsInvitationSerializer.new(invitation)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert attributes[:member]
    assert_not attributes[:admin]
  end

  test "should include account relationship" do
    serializer = AccountsInvitationSerializer.new(@invitation)
    serialized = serializer.serializable_hash

    assert serialized[:data][:relationships][:account]
    assert_equal @invitation.account_id, serialized[:data][:relationships][:account][:data][:id]
  end

  test "should include invited_by relationship" do
    serializer = AccountsInvitationSerializer.new(@invitation)
    serialized = serializer.serializable_hash

    assert serialized[:data][:relationships][:invited_by]
    assert_equal @invitation.invited_by_id, serialized[:data][:relationships][:invited_by][:data][:id]
  end

  test "should have correct type" do
    serializer = AccountsInvitationSerializer.new(@invitation)
    serialized = serializer.serializable_hash

    assert_equal "accounts_invitation", serialized[:data][:type].to_s
  end

  test "should have correct id" do
    serializer = AccountsInvitationSerializer.new(@invitation)
    serialized = serializer.serializable_hash

    assert_equal @invitation.id, serialized[:data][:id]
  end
end
