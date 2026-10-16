require "test_helper"

# Endpoints that email an address the caller names. Without these limits anyone
# could make the app mail a stranger over and over, and the sending domain's
# reputation would pay for it. Each limit is the one declared on the controller.
class MailThrottleTest < ActionDispatch::IntegrationTest
  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
  end

  def post_password_reset(email, ip: nil)
    post shopkeeper_password_url,
      params: {email: email, redirect_url: "http://www.example.com/reset"},
      headers: ip ? {"REMOTE_ADDR" => ip} : {},
      as: :json
  end

  def post_confirmation(email, ip: nil)
    post shopkeeper_confirmation_url,
      params: {email: email, redirect_url: "http://www.example.com/confirm"},
      headers: ip ? {"REMOTE_ADDR" => ip} : {},
      as: :json
  end

  def assert_throttled
    assert_response :too_many_requests
    assert_equal 429, response.parsed_body["code"]
    assert_equal I18n.t("errors.messages.too_many_requests"), response.parsed_body["error_message"]
  end

  # PasswordsController: 5 per minute per IP
  test "the sixth password reset from the same IP within a minute is rate-limited" do
    5.times do |i|
      post_password_reset("noone#{i}@example.com")
      assert_not_equal 429, response.status, "request #{i + 1} should not be throttled"
    end

    assert_no_enqueued_emails { post_password_reset(@shopkeeper.email) }
    assert_throttled
  end

  # PasswordsController: 3 per hour per address, whatever the IP
  test "the fourth password reset for one address within an hour is rate-limited" do
    3.times do |i|
      post_password_reset(@shopkeeper.email, ip: "10.0.0.#{i + 1}")
      assert_not_equal 429, response.status, "request #{i + 1} should not be throttled"
    end

    assert_no_enqueued_emails { post_password_reset(" #{@shopkeeper.email.upcase} ", ip: "10.0.0.99") }
    assert_throttled
  end

  # ConfirmationsController: 5 per minute per IP
  test "the sixth confirmation resend from the same IP within a minute is rate-limited" do
    5.times do |i|
      post_confirmation("noone#{i}@example.com")
      assert_not_equal 429, response.status, "request #{i + 1} should not be throttled"
    end

    assert_no_enqueued_emails { post_confirmation(@shopkeeper.email) }
    assert_throttled
  end

  # ConfirmationsController: 3 per hour per address, whatever the IP
  test "the fourth confirmation resend for one address within an hour is rate-limited" do
    3.times do |i|
      post_confirmation(@shopkeeper.email, ip: "10.0.0.#{i + 1}")
      assert_not_equal 429, response.status, "request #{i + 1} should not be throttled"
    end

    assert_no_enqueued_emails { post_confirmation(@shopkeeper.email.upcase, ip: "10.0.0.99") }
    assert_throttled
  end

  # Accounts::AccountsInvitationsController: 20 sends (create + resend) per hour per shopkeeper
  test "the twenty-first invitation email from one shopkeeper within an hour is rate-limited" do
    headers = @shopkeeper.create_new_auth_token

    19.times do |i|
      post api_v1_shopkeeper_account_accounts_invitations_url(@account),
        params: {accounts_invitation: {name: "Invitee #{i}", email: "invitee#{i}@example.com", member: true}},
        headers: headers
      assert_response :created
    end

    invitation = @account.accounts_invitations.first
    post resend_api_v1_shopkeeper_account_accounts_invitation_path(@account, invitation.token), headers: headers
    assert_response :success

    assert_no_enqueued_emails do
      post resend_api_v1_shopkeeper_account_accounts_invitation_path(@account, invitation.token), headers: headers
    end
    assert_throttled
  end
end
