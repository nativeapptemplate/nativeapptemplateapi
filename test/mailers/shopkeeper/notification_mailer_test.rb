require "test_helper"

class Shopkeeper::NotificationMailerTest < ActionMailer::TestCase
  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
    @invitation = AccountsInvitation.create!(
      account: @account,
      name: "Invited User",
      email: "invited@example.com",
      member: true,
      invited_by: @shopkeeper
    )
  end

  test "invited renders the expected subject, recipient, and body" do
    mail = Shopkeeper::NotificationMailer.with(accounts_invitation: @invitation).invited

    expected_subject = I18n.t(
      "shopkeeper.notification_mailer.invited.subject",
      inviter: @shopkeeper.name,
      account: @account.name
    )
    assert_equal expected_subject, mail.subject
    assert_equal [@invitation.email], mail.to
    assert_equal [ConfigSettings.email.default_from], mail.from
    assert_match @invitation.token, mail.body.encoded
    assert_match @account.name, mail.body.encoded
  end

  test "confirmation_instructions renders the expected subject, recipient, and body" do
    mail = Shopkeeper::NotificationMailer.with(
      resource: @shopkeeper,
      token: "confirm-token-123",
      opts: {redirect_url: "http://example.com/confirm", client_config: "default"}
    ).confirmation_instructions

    assert_equal I18n.t("shopkeeper.notification_mailer.confirmation_instructions.subject"), mail.subject
    assert_equal [@shopkeeper.email], mail.to
    assert_match "confirm-token-123", mail.body.encoded
    assert_match @shopkeeper.email, mail.body.encoded
  end

  test "confirmation_instructions uses opts[:to] when provided" do
    mail = Shopkeeper::NotificationMailer.with(
      resource: @shopkeeper,
      token: "tok",
      opts: {to: "override@example.com", redirect_url: "http://example.com/confirm", client_config: "default"}
    ).confirmation_instructions

    assert_equal ["override@example.com"], mail.to
    assert_match "override@example.com", mail.body.encoded
  end

  test "reset_password_instructions renders the expected subject, recipient, and body" do
    mail = Shopkeeper::NotificationMailer.with(
      resource: @shopkeeper,
      token: "reset-token-xyz",
      opts: {redirect_url: "http://example.com/reset", client_config: "default"}
    ).reset_password_instructions

    assert_equal I18n.t("shopkeeper.notification_mailer.reset_password_instructions.subject"), mail.subject
    assert_equal [@shopkeeper.email], mail.to
    assert_match "reset-token-xyz", mail.body.encoded
  end
end
