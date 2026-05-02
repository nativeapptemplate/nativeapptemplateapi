require "test_helper"

class ShopkeeperAuth::ConfirmationResultsControllerTest < ActionDispatch::IntegrationTest
  test "show renders the success page" do
    get shopkeeper_auth_confirmation_result_url

    assert_response :success
    assert_match I18n.t("devise_token_auth.confirmations.successfully_confirmed"), response.body
  end

  test "show uses the minimal layout" do
    get shopkeeper_auth_confirmation_result_url

    assert_response :success
    assert_match(/text\/html/, response.media_type)
  end
end
