require "test_helper"

class Api::V1::Shopkeeper::AccountsInvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
    @invitee = shopkeepers(:two)
    @invitation = AccountsInvitation.create!(
      account: @account,
      name: "Invited User",
      email: @invitee.email,
      member: true
    )
  end

  test "show returns invitation details" do
    get api_v1_shopkeeper_accounts_invitation_url(@invitation.token),
      headers: @invitee.create_new_auth_token

    assert_response :success

    json = response.parsed_body
    assert_equal @invitation.name, json["data"]["attributes"]["name"]
    assert_equal @invitation.email, json["data"]["attributes"]["email"]
  end

  test "show matches the invited email case-insensitively" do
    @invitation.update_column(:email, @invitee.email.upcase)

    get api_v1_shopkeeper_accounts_invitation_url(@invitation.token),
      headers: @invitee.create_new_auth_token

    assert_response :success
  end

  test "show returns 404 for invalid token" do
    get api_v1_shopkeeper_accounts_invitation_url("invalid"),
      headers: @invitee.create_new_auth_token

    assert_not_found
  end

  test "show returns 404 to a shopkeeper the invitation was not sent to" do
    get api_v1_shopkeeper_accounts_invitation_url(@invitation.token),
      headers: @shopkeeper.create_new_auth_token

    assert_not_found
  end

  test "update accepts invitation" do
    # Note: @invitee.create_default_account creates 1 AccountsShopkeeper
    # and accepting invitation creates another, so count increases by 2
    assert_difference "AccountsShopkeeper.count", 2 do
      assert_difference "AccountsInvitation.count", -1 do
        patch api_v1_shopkeeper_accounts_invitation_url(@invitation.token),
          headers: @invitee.create_new_auth_token
      end
    end

    assert_response :success
  end

  test "update returns 404 to a shopkeeper the invitation was not sent to" do
    outsider = Shopkeeper.create!(
      name: "Outsider", email: "outsider@example.com", password: "password", confirmed_at: Time.current,
      **@invitee.slice(:time_zone, :current_platform, :confirmed_privacy_version, :confirmed_terms_version).symbolize_keys
    )
    outsider.create_default_account

    assert_no_difference ["AccountsShopkeeper.count", "AccountsInvitation.count"] do
      patch api_v1_shopkeeper_accounts_invitation_url(@invitation.token),
        headers: outsider.create_new_auth_token
    end

    assert_not_found
    assert_not @account.accounts_shopkeepers.exists?(shopkeeper: outsider)
  end

  test "update returns error when invitation cannot be accepted" do
    # Shopkeeper already in account
    AccountsShopkeeper.create!(
      account: @account,
      shopkeeper: @invitee,
      member: true
    )

    patch api_v1_shopkeeper_accounts_invitation_url(@invitation.token),
      headers: @invitee.create_new_auth_token

    assert_response :unprocessable_entity
    assert_equal 422, response.parsed_body["code"]
    assert response.parsed_body["error_message"].present?
  end

  test "destroy rejects invitation" do
    assert_difference "AccountsInvitation.count", -1 do
      delete api_v1_shopkeeper_accounts_invitation_url(@invitation.token),
        headers: @invitee.create_new_auth_token
    end

    assert_response :success
  end

  test "destroy returns 404 to a shopkeeper the invitation was not sent to" do
    assert_no_difference "AccountsInvitation.count" do
      delete api_v1_shopkeeper_accounts_invitation_url(@invitation.token),
        headers: @shopkeeper.create_new_auth_token
    end

    assert_not_found
  end

  test "show returns 410 for expired invitation" do
    @invitation.update_column(:created_at, (AccountsInvitation::EXPIRES_IN + 1.minute).ago)

    get api_v1_shopkeeper_accounts_invitation_url(@invitation.token),
      headers: @invitee.create_new_auth_token

    assert_response :gone
    assert_equal 410, response.parsed_body["code"]
    assert_equal I18n.t("api.shopkeeper.accounts_invitations.expired"), response.parsed_body["error_message"]
  end

  test "update returns 410 for expired invitation" do
    @invitation.update_column(:created_at, (AccountsInvitation::EXPIRES_IN + 1.minute).ago)

    patch api_v1_shopkeeper_accounts_invitation_url(@invitation.token),
      headers: @invitee.create_new_auth_token

    assert_response :gone
    assert_equal 410, response.parsed_body["code"]
    assert_equal I18n.t("api.shopkeeper.accounts_invitations.expired"), response.parsed_body["error_message"]
  end

  test "token lookups are rate limited per shopkeeper" do
    headers = @shopkeeper.create_new_auth_token

    # 10 lookups per minute are allowed (the limit in the controller); the 11th is refused
    10.times do |i|
      get api_v1_shopkeeper_accounts_invitation_url(format("%06d", i)), headers: headers
      assert_response :not_found
    end

    get api_v1_shopkeeper_accounts_invitation_url(@invitation.token), headers: headers

    assert_response :too_many_requests
    assert_equal 429, response.parsed_body["code"]
    assert_equal I18n.t("errors.messages.too_many_requests"), response.parsed_body["error_message"]
  end

  test "requires authentication" do
    get api_v1_shopkeeper_accounts_invitation_url(@invitation.token)

    assert_response :unauthorized
  end

  private

  def assert_not_found
    assert_response :not_found
    assert_equal 404, response.parsed_body["code"]
    assert_equal I18n.t("api.shopkeeper.accounts_invitations.not_found"), response.parsed_body["error_message"]
  end
end
