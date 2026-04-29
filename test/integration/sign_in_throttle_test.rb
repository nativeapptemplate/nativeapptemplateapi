require "test_helper"

class SignInThrottleTest < ActionDispatch::IntegrationTest
  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
  end

  def post_sign_in(email:, password: "password", ip: nil)
    headers = {source: "ios"}
    headers["REMOTE_ADDR"] = ip if ip

    post shopkeeper_session_url,
      params: {email: email, password: password},
      headers: headers,
      as: :json
  end

  test "the sixth sign-in from the same IP within the window is rate-limited" do
    5.times { post_sign_in(email: "noone#{_1}@example.com", password: "wrong") }

    post_sign_in(email: "noone5@example.com", password: "wrong")

    assert_response :too_many_requests
    assert_equal 429, response.parsed_body["code"]
    assert_equal I18n.t("errors.messages.too_many_logins"), response.parsed_body["error_message"]
  end

  test "the sixth sign-in attempt against the same email from different IPs is rate-limited" do
    5.times do |i|
      post_sign_in(email: @shopkeeper.email, password: "wrong", ip: "10.0.0.#{i + 1}")
    end

    post_sign_in(email: @shopkeeper.email, password: "wrong", ip: "10.0.0.99")

    assert_response :too_many_requests
    assert_equal 429, response.parsed_body["code"]
    assert_equal I18n.t("errors.messages.too_many_logins"), response.parsed_body["error_message"]
  end
end
