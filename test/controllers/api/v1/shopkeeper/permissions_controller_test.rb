require "test_helper"

class Api::V1::Shopkeeper::PermissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
  end

  test "index returns permissions and metadata" do
    get api_v1_shopkeeper_permissions_url, headers: @shopkeeper.create_new_auth_token

    assert_response :success

    json = response.parsed_body
    assert json["data"].present?
    assert json["meta"].present?
    assert json["meta"]["ios_app_version"].present?
    assert json["meta"]["android_app_version"].present?
    assert_not_nil json["meta"]["should_update_privacy"]
    assert_not_nil json["meta"]["should_update_terms"]
    assert json["meta"]["maximum_queue_number_length"].present?
    assert json["meta"]["shop_limit_count"].present?
    assert json["meta"]["account_limit_count"].present?
    assert json["meta"]["accounts_shopkeeper_limit_count"].present?
  end

  test "index sets should_update_privacy to true when version is outdated" do
    @shopkeeper.update!(confirmed_privacy_version: "0.0.0")

    get api_v1_shopkeeper_permissions_url, headers: @shopkeeper.create_new_auth_token

    assert_response :success
    assert_equal true, response.parsed_body["meta"]["should_update_privacy"]
  end

  test "index sets should_update_privacy to false when version is current" do
    @shopkeeper.update!(confirmed_privacy_version: PrivacyVersion.current_version)

    get api_v1_shopkeeper_permissions_url, headers: @shopkeeper.create_new_auth_token

    assert_response :success
    assert_equal false, response.parsed_body["meta"]["should_update_privacy"]
  end

  test "index sets should_update_terms to true when version is outdated" do
    @shopkeeper.update!(confirmed_terms_version: "0.0.0")

    get api_v1_shopkeeper_permissions_url, headers: @shopkeeper.create_new_auth_token

    assert_response :success
    assert_equal true, response.parsed_body["meta"]["should_update_terms"]
  end

  test "index sets should_update_terms to false when version is current" do
    @shopkeeper.update!(confirmed_terms_version: TermsVersion.current_version)

    get api_v1_shopkeeper_permissions_url, headers: @shopkeeper.create_new_auth_token

    assert_response :success
    assert_equal false, response.parsed_body["meta"]["should_update_terms"]
  end

  test "index requires authentication" do
    get api_v1_shopkeeper_permissions_url

    assert_response :unauthorized
  end
end
