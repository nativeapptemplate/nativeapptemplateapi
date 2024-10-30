require "test_helper"

class ShopkeeperAuth::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "returns errors if invalid params submitted" do
    post shopkeeper_registration_url, params: {}
    assert_response :unprocessable_entity
    assert response.parsed_body["error_message"]
    assert_equal I18n.t("errors.messages.validate_sign_up_params"), response.parsed_body["error_message"]
  end

  test "returns shopkeeper and api token on success" do
    assert_difference "Shopkeeper.count" do
      post shopkeeper_registration_url, params: {email: "api-shopkeeper@example.com", name: "API Shopkeeper", password: "password", time_zone: "Tokyo", current_platform: "ios"}
      assert_response :success
    end

    shopkeeper = Shopkeeper.last

    # Account name should match shopkeeper's name
    assert_equal "API Shopkeeper", shopkeeper.personal_account.name

    # Returns an API token
    assert_equal shopkeeper.token, response.parsed_body["token"]
  end

  test "delete current shopkeeper" do
    assert_difference "Shopkeeper.count", -1 do
      delete shopkeeper_registration_url, headers: shopkeeper.create_new_auth_token
      assert_response :success
    end
  end

  def shopkeeper
    @shopkeeper ||= shopkeepers(:one)
  end
end
