require "test_helper"

class Api::V1::Shopkeeper::Accounts::AccountsInvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first

    @invitation = AccountsInvitation.create!(
      account: @account,
      name: "Invited User",
      email: "invited@example.com",
      invited_by: @shopkeeper,
      junior_member: true
    )
  end

  test "index returns all invitations for account" do
    AccountsInvitation.create!(
      account: @account,
      name: "Another User",
      email: "another@example.com",
      junior_member: true
    )

    get api_v1_shopkeeper_account_accounts_invitations_url(@account),
      headers: @shopkeeper.create_new_auth_token

    assert_response :success
    assert_equal 2, response.parsed_body["data"].length
  end

  test "show returns invitation details" do
    get api_v1_shopkeeper_account_accounts_invitation_url(@account, @invitation.token),
      headers: @shopkeeper.create_new_auth_token

    assert_response :success
    assert_equal @invitation.name, response.parsed_body["data"]["attributes"]["name"]
  end

  test "create creates and sends invitation" do
    assert_difference "AccountsInvitation.count", 1 do
      post api_v1_shopkeeper_account_accounts_invitations_url(@account),
        params: {
          accounts_invitation: {
            name: "New User",
            email: "newuser@example.com",
            junior_member: true
          }
        },
        headers: @shopkeeper.create_new_auth_token
    end

    assert_response :created
    assert_enqueued_emails 1
  end

  test "create returns error for invalid data" do
    assert_no_difference "AccountsInvitation.count" do
      post api_v1_shopkeeper_account_accounts_invitations_url(@account),
        params: {
          accounts_invitation: {
            name: "",
            email: "invalid@example.com",
            junior_member: true
          }
        },
        headers: @shopkeeper.create_new_auth_token
    end

    assert_response :unprocessable_entity
  end

  test "create requires admin role" do
    other_shopkeeper = shopkeepers(:two)
    AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      junior_member: true
    )

    post api_v1_shopkeeper_account_accounts_invitations_url(@account),
      params: {
        accounts_invitation: {
          name: "New User",
          email: "newuser@example.com",
          junior_member: true
        }
      },
      headers: other_shopkeeper.create_new_auth_token

    assert_response :unauthorized
  end

  test "update updates invitation" do
    patch api_v1_shopkeeper_account_accounts_invitation_url(@account, @invitation.token),
      params: {
        accounts_invitation: {
          name: "Updated Name",
          senior_member: true,
          junior_member: false
        }
      },
      headers: @shopkeeper.create_new_auth_token

    assert_response :success
    assert_equal "Updated Name", @invitation.reload.name
    assert @invitation.senior_member?
  end

  test "update returns error for invalid data" do
    patch api_v1_shopkeeper_account_accounts_invitation_url(@account, @invitation.token),
      params: {
        accounts_invitation: {
          name: ""
        }
      },
      headers: @shopkeeper.create_new_auth_token

    assert_response :unprocessable_entity
  end

  test "update requires admin role" do
    other_shopkeeper = shopkeepers(:two)
    AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      junior_member: true
    )

    patch api_v1_shopkeeper_account_accounts_invitation_url(@account, @invitation.token),
      params: {accounts_invitation: {name: "Updated"}},
      headers: other_shopkeeper.create_new_auth_token

    assert_response :unauthorized
  end

  test "destroy deletes invitation" do
    assert_difference "AccountsInvitation.count", -1 do
      delete api_v1_shopkeeper_account_accounts_invitation_url(@account, @invitation.token),
        headers: @shopkeeper.create_new_auth_token
    end

    assert_response :success
  end

  test "destroy requires admin role" do
    other_shopkeeper = shopkeepers(:two)
    AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      junior_member: true
    )

    delete api_v1_shopkeeper_account_accounts_invitation_url(@account, @invitation.token),
      headers: other_shopkeeper.create_new_auth_token

    assert_response :unauthorized
  end

  test "resend sends invitation email again" do
    post resend_api_v1_shopkeeper_account_accounts_invitation_path(@account, @invitation.token),
      headers: @shopkeeper.create_new_auth_token

    assert_response :success
  end

  test "resend requires admin role" do
    other_shopkeeper = Shopkeeper.create!(
      name: "Other User",
      email: "other123@example.com",
      password: "password",
      current_platform: "ios"
    )
    AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: other_shopkeeper,
      junior_member: true
    )

    post resend_api_v1_shopkeeper_account_accounts_invitation_path(@account, @invitation.token),
      headers: other_shopkeeper.create_new_auth_token

    assert_response :unauthorized
  end

  test "requires authentication" do
    get api_v1_shopkeeper_account_accounts_invitations_url(@account)

    assert_response :unauthorized
  end
end
