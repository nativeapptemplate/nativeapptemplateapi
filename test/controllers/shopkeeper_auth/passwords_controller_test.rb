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
        redirect_url: "http://localhost:3000/reset"
      },
      as: :json

    assert_response :success
  end

  test "should return error when email is missing" do
    post shopkeeper_password_url,
      params: {redirect_url: "http://localhost:3000/reset"},
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
        redirect_url: "http://localhost:3000/reset"
      },
      as: :json

    assert_response :ok
    assert JSON.parse(response.body)["success"]
  end
end
