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

  # Bug: deleting the inviter nullifies invited_by, and resending such an
  # invitation raised NoMethodError on nil.name inside the mail job. The mail
  # now names the app instead (config/settings.yml display_name).
  test "invited names the app when the inviter has been deleted" do
    @invitation.update!(invited_by: nil)

    mail = Shopkeeper::NotificationMailer.with(accounts_invitation: @invitation).invited

    expected_subject = I18n.t(
      "shopkeeper.notification_mailer.invited.subject",
      inviter: ConfigSettings.display_name,
      account: @account.name
    )
    assert_equal expected_subject, mail.subject
    assert_equal [@invitation.email], mail.to
    assert_match @invitation.token, mail.body.encoded
    assert_match "#{ConfigSettings.display_name} has invited you", mail.text_part.body.decoded
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

  # Mails name the app by its display name ("Native App Template"), not the
  # identifier-like name ("NativeAppTemplate"), in English and Japanese
  %i[en ja].each do |locale|
    test "invited names the app by its display name in #{locale}" do
      I18n.with_locale(locale) do
        mail = Shopkeeper::NotificationMailer.with(accounts_invitation: @invitation).invited
        app = ConfigSettings.display_name

        [mail.html_part.body.decoded, mail.text_part.body.decoded].each do |body|
          assert_includes strip_tags(body), strip_tags(I18n.t("shopkeeper.notification_mailer.invited.enter_your_invitation_code_in_the_mobile_app_html", mobile_app: app))
          assert_includes strip_tags(body), strip_tags(I18n.t("shopkeeper.notification_mailer.invited.open_mobile_app_html", mobile_app: app))
          refute_identifier_name body
        end
      end
    end

    test "invited leaves out the store links while their URLs are blank in #{locale}" do
      I18n.with_locale(locale) do
        mail = Shopkeeper::NotificationMailer.with(accounts_invitation: @invitation).invited

        [mail.html_part.body.decoded, mail.text_part.body.decoded].each do |body|
          refute_includes body, I18n.t("shopkeeper.notification_mailer.invited.ios_app", mobile_app: ConfigSettings.display_name)
          refute_includes body, I18n.t("shopkeeper.notification_mailer.invited.android_app", mobile_app: ConfigSettings.display_name)
          refute_includes body, "apps.apple.com"
          refute_includes body, "play.google.com"
        end
      end
    end

    test "invited links each store whose URL is set in #{locale}" do
      with_store_urls(app_store: "https://apps.apple.com/app/example/id123", play_store: "") do
        I18n.with_locale(locale) do
          mail = Shopkeeper::NotificationMailer.with(accounts_invitation: @invitation).invited
          ios = I18n.t("shopkeeper.notification_mailer.invited.ios_app", mobile_app: ConfigSettings.display_name)
          android = I18n.t("shopkeeper.notification_mailer.invited.android_app", mobile_app: ConfigSettings.display_name)

          assert_includes mail.html_part.body.decoded, %(<a target="_blank" href="https://apps.apple.com/app/example/id123">#{ios}</a>)
          assert_includes mail.text_part.body.decoded, "#{ios}: https://apps.apple.com/app/example/id123"
          [mail.html_part.body.decoded, mail.text_part.body.decoded].each do |body|
            refute_includes body, android
          end
        end
      end

      with_store_urls(app_store: "https://apps.apple.com/app/example/id123", play_store: "https://play.google.com/store/apps/details?id=com.example") do
        I18n.with_locale(locale) do
          mail = Shopkeeper::NotificationMailer.with(accounts_invitation: @invitation).invited
          android = I18n.t("shopkeeper.notification_mailer.invited.android_app", mobile_app: ConfigSettings.display_name)

          assert_includes mail.text_part.body.decoded, "#{android}: https://play.google.com/store/apps/details?id=com.example"
          assert_includes mail.html_part.body.decoded, "#{android}</a>"
        end
      end
    end

    test "mail footer names the app by its display name in #{locale}" do
      I18n.with_locale(locale) do
        mail = Shopkeeper::NotificationMailer.with(
          resource: @shopkeeper,
          token: "reset-token-xyz",
          opts: {redirect_url: "http://example.com/reset", client_config: "default"}
        ).reset_password_instructions

        assert_includes mail.text_part.body.decoded, "#{ConfigSettings.display_name}: #{ConfigSettings.site.url}"
        assert_includes mail.html_part.body.decoded, "#{Date.current.year} #{ConfigSettings.display_name} All rights reserved."
        assert_includes mail.html_part.body.decoded, %(>#{ConfigSettings.display_name}</a>)
        [mail.html_part.body.decoded, mail.text_part.body.decoded].each do |body|
          refute_identifier_name body
        end
      end
    end
  end

  test "mails come from the display name" do
    mail = Shopkeeper::NotificationMailer.with(
      resource: @shopkeeper,
      token: "reset-token-xyz",
      opts: {redirect_url: "http://example.com/reset", client_config: "default"}
    ).reset_password_instructions

    assert_equal [ConfigSettings.display_name], mail[:from].display_names
  end

  private

  # An app whose display name is one word ("Barber") has the same identifier
  # name, so there is nothing to tell apart
  def refute_identifier_name(body)
    [ConfigSettings.site.name, ConfigSettings.business.name].each do |name|
      refute_includes body, name unless ConfigSettings.display_name.include?(name)
    end
  end

  def strip_tags(html)
    ActionController::Base.helpers.strip_tags(html)
  end

  def with_store_urls(app_store:, play_store:)
    original = [ConfigSettings.mobile_app.app_store_url, ConfigSettings.mobile_app.play_store_url]
    ConfigSettings.mobile_app.app_store_url = app_store
    ConfigSettings.mobile_app.play_store_url = play_store
    yield
  ensure
    ConfigSettings.mobile_app.app_store_url, ConfigSettings.mobile_app.play_store_url = original
  end
end
