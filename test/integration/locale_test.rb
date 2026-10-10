require "test_helper"

# A signed-in shopkeeper gets the language stored in shopkeepers.locale. Other
# requests use the language the client asks for in Accept-Language (English
# or Japanese), falling back to English. iOS sends the header from the
# device's preferred languages; other clients must add it themselves.
class LocaleTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
  end

  # Sign in with a wrong password and return the error message
  def bad_credentials_message(accept_language = nil)
    headers = accept_language ? {"Accept-Language" => accept_language} : {}
    post shopkeeper_session_url, params: {email: @shopkeeper.email, password: "wrong-password"}, headers: headers
    assert_response :unauthorized
    response.parsed_body["error_message"]
  end

  def bad_credentials(locale)
    I18n.t("devise_token_auth.sessions.bad_credentials", locale: locale)
  end

  # Like production: no debug page, so routing errors reach ErrorsController
  def without_detailed_exceptions
    env_config = Rails.application.env_config
    original = env_config["action_dispatch.show_detailed_exceptions"]
    env_config["action_dispatch.show_detailed_exceptions"] = false
    yield
  ensure
    env_config["action_dispatch.show_detailed_exceptions"] = original
  end

  def auth_headers(accept_language = nil)
    headers = @shopkeeper.create_new_auth_token
    accept_language ? headers.merge("Accept-Language" => accept_language) : headers
  end

  def sign_up(params = {}, headers = {})
    post shopkeeper_registration_url,
      params: {email: "new@example.com", name: "New", password: "password", time_zone: "Tokyo", current_platform: "ios"}.merge(params),
      headers: headers
  end

  test "the two locales really differ" do
    assert_not_equal bad_credentials(:en), bad_credentials(:ja)
  end

  test "answers in English without Accept-Language" do
    assert_equal bad_credentials(:en), bad_credentials_message
  end

  test "answers in Japanese for ja" do
    assert_equal bad_credentials(:ja), bad_credentials_message("ja")
  end

  test "matches a regional tag such as ja-JP" do
    assert_equal bad_credentials(:ja), bad_credentials_message("ja-JP")
  end

  test "picks the language with the highest quality value" do
    assert_equal bad_credentials(:ja), bad_credentials_message("en;q=0.5, ja")
    assert_equal bad_credentials(:en), bad_credentials_message("ja;q=0.4, en;q=0.8")
  end

  # iOS sends e.g. "ja-JP, en-JP;q=0.9" for a Japanese device
  test "keeps header order between equal quality values" do
    assert_equal bad_credentials(:ja), bad_credentials_message("ja-JP, en-JP;q=0.9")
    assert_equal bad_credentials(:en), bad_credentials_message("en-US, ja-JP")
  end

  test "skips a language the client refuses with q=0" do
    assert_equal bad_credentials(:en), bad_credentials_message("ja;q=0, fr")
  end

  test "falls back to English for unsupported languages" do
    assert_equal bad_credentials(:en), bad_credentials_message("fr-FR, de;q=0.8")
    assert_equal bad_credentials(:en), bad_credentials_message("*")
  end

  test "ignores a malformed header" do
    assert_equal bad_credentials(:en), bad_credentials_message(",;q=abc, ;, ja;q=x")
  end

  test "does not leak the locale into the next request" do
    bad_credentials_message("ja")

    assert_equal bad_credentials(:en), bad_credentials_message
  end

  # errors.format "%{attribute}%{message}" + shop name "店舗名" + errors.messages.blank "を入力してください"
  test "validation errors use Japanese attribute names and messages" do
    @shopkeeper.update!(locale: "ja")
    post api_v1_shopkeeper_shops_url,
      params: {shop: {name: "", time_zone: "Tokyo"}},
      headers: auth_headers

    assert_response :unprocessable_entity
    assert_equal "店舗名を入力してください", response.parsed_body["error_message"]
  end

  test "several sign-up errors are joined with Japanese commas" do
    post shopkeeper_registration_url,
      params: {email: "not-an-email", password: "short", name: "", time_zone: "Tokyo", current_platform: "ios"},
      headers: {"Accept-Language" => "ja"}

    assert_response :unprocessable_entity
    message = response.parsed_body["error_message"]
    assert_includes message, "、"
    assert_no_match(/, and |, /, message)
  end

  # ConfigSettings.minimum_password_length is 8
  test "the password reset form is fully Japanese" do
    get edit_shopkeeper_auth_reset_password_url(reset_password_token: "x"), headers: {"Accept-Language" => "ja"}

    assert_response :success
    assert_includes response.body, "（8文字以上）"
    assert_not_includes response.body, "characters minimum"
  end

  test "an unauthenticated API request answers in Japanese" do
    get api_v1_shopkeeper_shops_url, headers: {"Accept-Language" => "ja"}

    assert_response :unauthorized
    assert_equal [I18n.t("devise.failure.unauthenticated", locale: :ja)], response.parsed_body["errors"]
    assert_not_equal I18n.t("devise.failure.unauthenticated", locale: :en), I18n.t("devise.failure.unauthenticated", locale: :ja)
  end

  test "a missing API record answers in the stored language" do
    @shopkeeper.update!(locale: "ja")
    get api_v1_shopkeeper_shop_url("00000000-0000-0000-0000-000000000000"), headers: auth_headers

    assert_response :not_found
    assert_equal I18n.t("not_found", locale: :ja), response.parsed_body["error_message"]
  end

  test "an unknown API route answers in Japanese" do
    without_detailed_exceptions do
      get "/api/v1/shopkeeper/no_such_route", headers: {"Accept-Language" => "ja"}
    end

    assert_response :not_found
    assert_equal I18n.t("not_found", locale: :ja), response.parsed_body["error_message"]
  end

  test "the HTML not-found page is Japanese" do
    without_detailed_exceptions do
      get "/no_such_page", headers: {"Accept-Language" => "ja"}
    end

    assert_response :not_found
    assert_includes response.body, I18n.t("error_pages.not_found.title", locale: :ja)
    assert_includes response.body, 'lang="ja"'
  end

  test "a throttled request answers in Japanese" do
    6.times { post shopkeeper_session_url, params: {email: "nobody@example.com", password: "x"}, headers: {"Accept-Language" => "ja"} }

    assert_response :too_many_requests
    assert_equal I18n.t("errors.messages.too_many_logins", locale: :ja), response.parsed_body["error_message"]
  end

  test "an invitation to a new email is written in the inviter's language" do
    @shopkeeper.update!(locale: "ja")
    perform_enqueued_jobs do
      post api_v1_shopkeeper_account_accounts_invitations_url(@account),
        params: {accounts_invitation: {name: "New User", email: "newuser@example.com", member: true}},
        headers: auth_headers("en")
    end

    assert_response :created
    mail = ActionMailer::Base.deliveries.last
    expected = I18n.t("shopkeeper.notification_mailer.invited.subject", locale: :ja, inviter: @shopkeeper.name, account: @account.name)
    assert_equal expected, mail.subject
    assert_includes mail.text_part.body.decoded, I18n.t("shopkeeper.notification_mailer.invited.you_can_accept_or_decline", locale: :ja)
  end

  test "a shop created by a Japanese shopkeeper gets a Japanese sample item tag" do
    @shopkeeper.update!(locale: "ja")
    post api_v1_shopkeeper_shops_url,
      params: {shop: {name: "新しい店", time_zone: "Tokyo"}},
      headers: auth_headers

    assert_response :created
    shop = Shop.find(response.parsed_body["data"]["id"])
    sample = ActsAsTenant.without_tenant { shop.item_tags.first }
    assert_equal I18n.t("sample_item_tag.name", locale: :ja), sample.name
    assert_equal I18n.t("sample_item_tag.description", locale: :ja), sample.description
  end

  # --- shopkeepers.locale ---

  test "a signed-in shopkeeper's stored language wins over Accept-Language" do
    missing_shop = api_v1_shopkeeper_shop_url("00000000-0000-0000-0000-000000000000")

    @shopkeeper.update!(locale: "ja")
    get missing_shop, headers: auth_headers("en")
    assert_equal I18n.t("not_found", locale: :ja), response.parsed_body["error_message"]

    @shopkeeper.update!(locale: "en")
    get missing_shop, headers: auth_headers("ja")
    assert_equal I18n.t("not_found", locale: :en), response.parsed_body["error_message"]
  end

  test "a failed sign-in still answers in the Accept-Language" do
    @shopkeeper.update!(locale: "ja")

    assert_equal bad_credentials(:en), bad_credentials_message("en")
  end

  test "sign-up stores the locale the app sends" do
    sign_up({locale: "ja"}, {"Accept-Language" => "en"})

    assert_response :success
    assert_equal "ja", Shopkeeper.find_by!(email: "new@example.com").locale
    assert_equal "ja", response.parsed_body["data"]["attributes"]["locale"]
  end

  test "sign-up reduces a regional locale such as ja-JP to its language" do
    sign_up(locale: "ja-JP")

    assert_equal "ja", Shopkeeper.find_by!(email: "new@example.com").locale
  end

  test "sign-up without a locale takes the Accept-Language" do
    sign_up({}, {"Accept-Language" => "ja-JP, en;q=0.9"})

    assert_equal "ja", Shopkeeper.find_by!(email: "new@example.com").locale
  end

  test "sign-up without a locale or Accept-Language stores English" do
    sign_up

    assert_equal "en", Shopkeeper.find_by!(email: "new@example.com").locale
  end

  # A device set to a language the API lacks must still be able to sign up
  test "sign-up with an unsupported locale falls back to the Accept-Language" do
    sign_up({locale: "fr"}, {"Accept-Language" => "ja"})

    assert_response :success
    assert_equal "ja", Shopkeeper.find_by!(email: "new@example.com").locale
  end

  test "the confirmation mail is written in the stored language" do
    perform_enqueued_jobs do
      sign_up({locale: "ja"}, {"Accept-Language" => "en"})
    end

    assert_equal I18n.t("shopkeeper.notification_mailer.confirmation_instructions.subject", locale: :ja),
      ActionMailer::Base.deliveries.last.subject
  end

  test "the profile update stores a new locale" do
    patch shopkeeper_registration_url, params: {locale: "ja"}, headers: auth_headers

    assert_response :success
    assert_equal "ja", @shopkeeper.reload.locale
    assert_equal "ja", response.parsed_body["data"]["attributes"]["locale"]
  end

  # errors.format "%{attribute}%{message}" + locale "言語" + errors.messages.inclusion "は一覧から選択してください"
  test "the profile update rejects an unsupported locale" do
    @shopkeeper.update!(locale: "ja")
    patch shopkeeper_registration_url, params: {locale: "fr"}, headers: auth_headers("en")

    assert_response :unprocessable_entity
    assert_equal "言語は一覧から選択してください", response.parsed_body["error_message"]
    assert_equal "ja", @shopkeeper.reload.locale
  end

  test "the reset password mail is written in the stored language" do
    @shopkeeper.update!(locale: "ja")

    perform_enqueued_jobs do
      post shopkeeper_password_url,
        params: {email: @shopkeeper.email, redirect_url: "http://www.example.com/reset"},
        headers: {"Accept-Language" => "en"},
        as: :json
    end

    assert_equal I18n.t("shopkeeper.notification_mailer.reset_password_instructions.subject", locale: :ja),
      ActionMailer::Base.deliveries.last.subject
  end

  test "an invitation to an existing shopkeeper is written in their language" do
    invitee = shopkeepers(:two)
    invitee.update!(locale: "ja")

    perform_enqueued_jobs do
      post api_v1_shopkeeper_account_accounts_invitations_url(@account),
        params: {accounts_invitation: {name: invitee.name, email: invitee.email.upcase, member: true}},
        headers: auth_headers
    end

    assert_response :created
    expected = I18n.t("shopkeeper.notification_mailer.invited.subject", locale: :ja, inviter: @shopkeeper.name, account: @account.name)
    assert_equal expected, ActionMailer::Base.deliveries.last.subject
  end
end
