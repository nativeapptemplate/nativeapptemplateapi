require "test_helper"

class ShopkeeperAuth::PasswordsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @shopkeeper = shopkeepers(:one)
    @email = @shopkeeper.email
  end

  test "should send reset password instructions" do
    post shopkeeper_password_url,
      params: {
        email: @email,
        redirect_url: "http://www.example.com/reset"
      },
      as: :json

    assert_response :success
  end

  # The apps send the API's own base URL. A reset link that redirects elsewhere
  # would hand the reset token to that site.
  test "rejects a reset redirect_url on another host and sends no email" do
    assert_no_enqueued_emails do
      post shopkeeper_password_url,
        params: {email: @email, redirect_url: "https://evil.example/reset"},
        as: :json
    end

    assert_response :unprocessable_entity
    assert_equal 422, response.parsed_body["code"]
    assert_equal I18n.t("devise_token_auth.passwords.not_allowed_redirect_url", redirect_url: "https://evil.example/reset"),
      response.parsed_body["error_message"]
  end

  test "rejects a host that only starts with the API host" do
    post shopkeeper_password_url,
      params: {email: @email, redirect_url: "http://www.example.com.evil.example/reset"},
      as: :json

    assert_response :unprocessable_entity
  end

  test "the reset link does not redirect the token to another host" do
    token = @shopkeeper.send(:set_reset_password_token)

    get edit_shopkeeper_password_url(reset_password_token: token, redirect_url: "https://evil.example/reset")

    assert_response :unprocessable_entity
  end

  test "the reset link redirects to the API's own host" do
    token = @shopkeeper.send(:set_reset_password_token)

    get edit_shopkeeper_password_url(reset_password_token: token, redirect_url: "http://www.example.com/reset")

    assert_response :redirect
    assert_equal "www.example.com", URI(response.location).host
  end

  test "should return error when email is missing" do
    post shopkeeper_password_url,
      params: {redirect_url: "http://www.example.com/reset"},
      as: :json

    assert_response :unauthorized
    assert_equal 401, JSON.parse(response.body)["code"]
  end

  test "should return error when redirect_url is missing" do
    post shopkeeper_password_url,
      params: {email: @email},
      as: :json

    assert_response :unauthorized
    assert_equal 401, JSON.parse(response.body)["code"]
  end

  test "should redirect with error when password update fails validation" do
    token = @shopkeeper.send(:set_reset_password_token)

    patch shopkeeper_password_url,
      params: {
        reset_password_token: token,
        password: "short",
        password_confirmation: "mismatch"
      }

    assert_response :redirect
    assert_match "edit", response.location
    follow_redirect!
    assert_select ".bg-yellow-50"
  end

  test "should return generic success for non-existent email to prevent enumeration" do
    post shopkeeper_password_url,
      params: {
        email: "nonexistent@example.com",
        redirect_url: "http://www.example.com/reset"
      },
      as: :json

    assert_response :ok
    assert JSON.parse(response.body)["success"]
  end
end
