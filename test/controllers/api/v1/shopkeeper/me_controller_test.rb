require "test_helper"

class Api::V1::Shopkeeper::MeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
  end

  test "update_confirmed_privacy_version updates shopkeeper privacy version" do
    current_version = PrivacyVersion.current_version
    @shopkeeper.update!(confirmed_privacy_version: "0.0.0")

    patch update_confirmed_privacy_version_api_v1_shopkeeper_me_path,
      headers: @shopkeeper.create_new_auth_token

    assert_response :success
    assert_equal current_version, @shopkeeper.reload.confirmed_privacy_version
  end

  test "update_confirmed_terms_version updates shopkeeper terms version" do
    current_version = TermsVersion.current_version
    @shopkeeper.update!(confirmed_terms_version: "0.0.0")

    patch update_confirmed_terms_version_api_v1_shopkeeper_me_path,
      headers: @shopkeeper.create_new_auth_token

    assert_response :success
    assert_equal current_version, @shopkeeper.reload.confirmed_terms_version
  end

  test "update_confirmed_privacy_version requires authentication" do
    patch update_confirmed_privacy_version_api_v1_shopkeeper_me_path

    assert_response :unauthorized
  end

  test "update_confirmed_terms_version requires authentication" do
    patch update_confirmed_terms_version_api_v1_shopkeeper_me_path

    assert_response :unauthorized
  end
end
