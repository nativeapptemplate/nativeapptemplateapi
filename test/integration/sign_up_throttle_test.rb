require "test_helper"

class SignUpThrottleTest < ActionDispatch::IntegrationTest
  def post_sign_up(email)
    post shopkeeper_registration_url,
      params: {
        name: "Throttle Test",
        email: email,
        password: "password",
        password_confirmation: "password",
        time_zone: "Tokyo",
        current_platform: "ios"
      },
      as: :json
  end

  test "the sixth sign-up from the same IP within an hour is rate-limited" do
    5.times do |i|
      post_sign_up("throttle#{i}@example.com")
      assert_not_equal 429, response.status, "request #{i + 1} should not be throttled"
    end

    post_sign_up("throttle5@example.com")

    assert_response :too_many_requests
    assert_equal 429, response.parsed_body["code"]
    assert_equal I18n.t("errors.messages.too_many_signups"), response.parsed_body["error_message"]
  end
end
