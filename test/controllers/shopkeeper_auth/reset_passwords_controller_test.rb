require "test_helper"

class ShopkeeperAuth::ResetPasswordsControllerTest < ActionDispatch::IntegrationTest
  test "show renders the success page" do
    get shopkeeper_auth_reset_password_url

    assert_response :success
    assert_match I18n.t("devise_token_auth.passwords.successfully_updated"), response.body
  end

  test "edit renders the password change form with minimum password length" do
    get edit_shopkeeper_auth_reset_password_url(reset_password_token: "abc123")

    assert_response :success
    assert_match I18n.t("change_your_password"), response.body
    assert_match ConfigSettings.minimum_password_length.to_s, response.body
  end

  test "edit includes the reset_password_token in the form" do
    get edit_shopkeeper_auth_reset_password_url(reset_password_token: "tok-xyz")

    assert_response :success
    assert_match "tok-xyz", response.body
  end
end
