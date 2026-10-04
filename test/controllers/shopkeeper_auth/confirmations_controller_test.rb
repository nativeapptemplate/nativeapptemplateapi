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
        redirect_url: "http://www.example.com/confirm"
      },
      as: :json

    assert_response :success
  end

  test "should return error when email is missing" do
    post shopkeeper_confirmation_url,
      params: {redirect_url: "http://www.example.com/confirm"},
      as: :json

    assert_response :unauthorized
    assert_equal 401, JSON.parse(response.body)["code"]
  end

  test "should return not found for non-existent email" do
    post shopkeeper_confirmation_url,
      params: {
        email: "nonexistent@example.com",
        redirect_url: "http://www.example.com/confirm"
      },
      as: :json

    assert_response :not_found
    assert_equal 404, JSON.parse(response.body)["code"]
  end

  test "a confirmation link never redirects to another host" do
    get shopkeeper_confirmation_url(confirmation_token: "invalid", redirect_url: "https://evil.example/confirm")

    assert_response :redirect
    assert_equal "www.example.com", URI(response.location).host
    assert_match %r{\A#{Regexp.escape(shopkeeper_auth_confirmation_result_url)}}, response.location
  end

  test "a confirmation link keeps a redirect_url on the API's own host" do
    get shopkeeper_confirmation_url(confirmation_token: "invalid", redirect_url: "http://www.example.com/confirm")

    assert_response :redirect
    assert_match %r{\Ahttp://www\.example\.com/confirm\?}, response.location
  end

  test "confirmation emails don't carry a redirect_url on another host" do
    post shopkeeper_confirmation_url,
      params: {email: @email, redirect_url: "https://evil.example/confirm"},
      as: :json

    assert_response :success
    mail = ActionMailer::Base.deliveries.last || perform_enqueued_jobs && ActionMailer::Base.deliveries.last
    assert mail, "a confirmation email should be sent"
    assert_no_match "evil.example", mail.body.encoded
  end

  test "should use default redirect_url when not provided" do
    post shopkeeper_confirmation_url,
      params: {email: @email},
      as: :json

    assert_response :success
  end
end
