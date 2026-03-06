require "test_helper"

class ShopkeeperAuth::ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @shopkeeper = shopkeepers(:one)
    @email = @shopkeeper.email
  end

  test "should send confirmation instructions" do
    post shopkeeper_confirmation_url,
      params: {
        email: @email,
        redirect_url: "http://localhost:3000/confirm"
      },
      as: :json

    assert_response :success
  end

  test "should return error when email is missing" do
    post shopkeeper_confirmation_url,
      params: {redirect_url: "http://localhost:3000/confirm"},
      as: :json

    assert_response :unauthorized
    assert_equal 401, JSON.parse(response.body)["code"]
  end

  test "should return not found for non-existent email" do
    post shopkeeper_confirmation_url,
      params: {
        email: "nonexistent@example.com",
        redirect_url: "http://localhost:3000/confirm"
      },
      as: :json

    assert_response :not_found
    assert_equal 404, JSON.parse(response.body)["code"]
  end

  test "should use default redirect_url when not provided" do
    post shopkeeper_confirmation_url,
      params: {email: @email},
      as: :json

    assert_response :success
  end
end
