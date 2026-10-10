require "test_helper"

# Responses use the language the client asks for in Accept-Language (English
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

  def auth_headers(accept_language)
    @shopkeeper.create_new_auth_token.merge("Accept-Language" => accept_language)
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
    post api_v1_shopkeeper_shops_url,
      params: {shop: {name: "", time_zone: "Tokyo"}},
      headers: auth_headers("ja")

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

  test "a missing API record answers in Japanese" do
    get api_v1_shopkeeper_shop_url("00000000-0000-0000-0000-000000000000"), headers: auth_headers("ja")

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

  test "an invitation sent during a Japanese request is written in Japanese" do
    perform_enqueued_jobs do
      post api_v1_shopkeeper_account_accounts_invitations_url(@account),
        params: {accounts_invitation: {name: "New User", email: "newuser@example.com", member: true}},
        headers: auth_headers("ja")
    end

    assert_response :created
    mail = ActionMailer::Base.deliveries.last
    expected = I18n.t("shopkeeper.notification_mailer.invited.subject", locale: :ja, inviter: @shopkeeper.name, account: @account.name)
    assert_equal expected, mail.subject
    assert_includes mail.text_part.body.decoded, I18n.t("shopkeeper.notification_mailer.invited.you_can_accept_or_decline", locale: :ja)
  end

  test "a shop created during a Japanese request gets a Japanese sample item tag" do
    post api_v1_shopkeeper_shops_url,
      params: {shop: {name: "新しい店", time_zone: "Tokyo"}},
      headers: auth_headers("ja")

    assert_response :created
    shop = Shop.find(response.parsed_body["data"]["id"])
    sample = ActsAsTenant.without_tenant { shop.item_tags.first }
    assert_equal I18n.t("sample_item_tag.name", locale: :ja), sample.name
    assert_equal I18n.t("sample_item_tag.description", locale: :ja), sample.description
  end
end
