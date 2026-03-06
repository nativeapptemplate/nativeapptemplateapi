require "test_helper"

class Api::V1::Shopkeeper::AccountsInvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
    @invitation = AccountsInvitation.create!(
      account: @account,
      name: "Invited User",
      email: "invited@example.com",
      junior_member: true
    )
  end

  test "show returns invitation details" do
    get api_v1_shopkeeper_accounts_invitation_url(@invitation.token),
      headers: @shopkeeper.create_new_auth_token

    assert_response :success

    json = response.parsed_body
    assert_equal @invitation.name, json["data"]["attributes"]["name"]
    assert_equal @invitation.email, json["data"]["attributes"]["email"]
  end

  test "show returns 404 for invalid token" do
    get api_v1_shopkeeper_accounts_invitation_url("invalid"),
      headers: @shopkeeper.create_new_auth_token

    assert_response :not_found
  end

  test "update accepts invitation" do
    other_shopkeeper = shopkeepers(:two)
    # Note: other_shopkeeper.create_default_account creates 1 AccountsShopkeeper
    # and accepting invitation creates another, so count increases by 2
    assert_difference "AccountsShopkeeper.count", 2 do
      assert_difference "AccountsInvitation.count", -1 do
        patch api_v1_shopkeeper_accounts_invitation_url(@invitation.token),
          headers: other_shopkeeper.create_new_auth_token
      end
    end

    assert_response :success
  end

  test "update returns error when invitation cannot be accepted" do
    # Shopkeeper already in account
    AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: shopkeepers(:two),
      junior_member: true
    )

    patch api_v1_shopkeeper_accounts_invitation_url(@invitation.token),
      headers: shopkeepers(:two).create_new_auth_token

    assert_response :unprocessable_entity
    assert response.parsed_body["error_message"].present?
  end

  test "destroy rejects invitation" do
    assert_difference "AccountsInvitation.count", -1 do
      delete api_v1_shopkeeper_accounts_invitation_url(@invitation.token),
        headers: @shopkeeper.create_new_auth_token
    end

    assert_response :success
  end

  test "requires authentication" do
    get api_v1_shopkeeper_accounts_invitation_url(@invitation.token)

    assert_response :unauthorized
  end
end
