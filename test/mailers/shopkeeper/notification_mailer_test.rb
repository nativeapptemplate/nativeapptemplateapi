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

  # The display name in From is what mail clients show as the sender. The
  # inviter's name is free text ("Apple Support"), so From names the app
  # (config/settings.yml display_name); the subject and body still say who
  # invited
  test "invited sends from the app's name, not the inviter's" do
    @shopkeeper.update!(name: "Apple Support")

    mail = Shopkeeper::NotificationMailer.with(accounts_invitation: @invitation).invited

    assert_equal ConfigSettings.display_name, mail[:from].display_names.first
    assert_includes mail.subject, "Apple Support"
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

  # The link opens the invitation in the app (iOS Universal Links, Android App
  # Links), served from this API's host (config/settings.yml app_links); the
  # code and the steps stay for when it can't
  test "invited links the invitation on the API's host in both parts" do
    mail = Shopkeeper::NotificationMailer.with(accounts_invitation: @invitation).invited
    link = "https://#{ConfigSettings.app.domain}/invitations/#{@invitation.token}"

    assert_includes mail.html_part.body.decoded, %(href="#{link}")
    assert_includes mail.text_part.body.decoded, link
    assert_includes mail.text_part.body.decoded, I18n.t("shopkeeper.notification_mailer.invited.enter_your_invitation_code")
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

  # The confirmation mail's heading is the shopkeeper's email address, one word
  # with no break opportunity. Wider than the card, it made iOS Mail shrink the
  # whole message, so the ground no longer filled the screen (dark mode showed
  # Mail's own gray around it). The card lets long words wrap
  test "the card lets a long email address wrap instead of widening the mail" do
    mail = Shopkeeper::NotificationMailer.with(
      resource: @shopkeeper,
      token: "tok",
      opts: {redirect_url: "http://example.com/confirm", client_config: "default"}
    ).confirmation_instructions

    card = Nokogiri::HTML(mail.html_part.body.decoded).at_css("td.card")
    assert_match(/overflow-wrap:\s*anywhere/, card["style"])
    assert_match(/word-break:\s*break-word/, card["style"])
  end

  # The layout fits phones (viewport) and follows the reader's dark mode
  test "the layout sets the viewport and has a dark color scheme" do
    mail = Shopkeeper::NotificationMailer.with(accounts_invitation: @invitation).invited
    html = Nokogiri::HTML(mail.html_part.body.decoded)

    assert html.at_css('meta[name="viewport"]')
    assert_includes html.at_css("style").text, "prefers-color-scheme: dark"
  end

  # The way into confirming and resetting is a filled button, not an underlined
  # text link
  test "confirmation and reset mails link through a filled button" do
    confirmation = Shopkeeper::NotificationMailer.with(
      resource: @shopkeeper,
      token: "confirm-token-123",
      opts: {redirect_url: "http://example.com/confirm", client_config: "default"}
    ).confirmation_instructions
    reset = Shopkeeper::NotificationMailer.with(
      resource: @shopkeeper,
      token: "reset-token-xyz",
      opts: {redirect_url: "http://example.com/reset", client_config: "default"}
    ).reset_password_instructions

    {
      confirmation => ["confirm-token-123", I18n.t("shopkeeper.notification_mailer.confirmation_instructions.confirm_account_link")],
      reset => ["reset-token-xyz", I18n.t("shopkeeper.notification_mailer.reset_password_instructions.password_change_link")]
    }.each do |mail, (token, label)|
      button = Nokogiri::HTML(mail.html_part.body.decoded).at_css("td.button-cell a")
      assert_equal label, button.text
      assert_includes button["href"], token
    end
  end

  # The invitation code stands out in a box, and the steps are a real list
  test "invited puts the code in a box and the steps in an ordered list" do
    mail = Shopkeeper::NotificationMailer.with(accounts_invitation: @invitation).invited
    html = Nokogiri::HTML(mail.html_part.body.decoded)

    assert_equal @invitation.token, html.at_css(".code").text.strip
    assert_equal 6, html.css("ol li").size
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

  # Bug: the named route took @resource as its format, so the link ended in
  # /password/edit.<shopkeeper id>, which put the shopkeeper's id in the URL
  test "reset_password_instructions links to /password/edit without the shopkeeper's id" do
    mail = Shopkeeper::NotificationMailer.with(
      resource: @shopkeeper,
      token: "reset-token-xyz",
      opts: {redirect_url: "http://example.com/reset", client_config: "default"}
    ).reset_password_instructions

    [mail.html_part.body.decoded, mail.text_part.body.decoded].each do |body|
      assert_match %r{/password/edit\?}, body
      assert_no_match @shopkeeper.id.to_s, body
    end
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
