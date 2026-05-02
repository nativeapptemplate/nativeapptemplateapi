require "test_helper"

class Api::V1::Shopkeeper::AccountsShopkeepersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first

    # Create a team account for testing
    @team_account = Account.create!(name: "Team Account", owner: @shopkeeper, personal: false)
    @team_accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @team_account,
      shopkeeper: @shopkeeper,
      admin: true
    )
  end

  test "index returns empty array for personal account" do
    get api_v1_shopkeeper_account_accounts_shopkeepers_url(@account),
      headers: @shopkeeper.create_new_auth_token

    assert_response :success
    assert_equal [], response.parsed_body["data"]
  end

  test "index returns accounts_shopkeepers for team account" do
    other_shopkeeper = shopkeepers(:two)
    AccountsShopkeeper.create!(
      account: @team_account,
      shopkeeper: other_shopkeeper,
      member: true
    )

    get api_v1_shopkeeper_account_accounts_shopkeepers_url(@team_account),
      headers: @shopkeeper.create_new_auth_token

    assert_response :success
    assert_equal 2, response.parsed_body["data"].length
  end

  test "show returns accounts_shopkeeper details" do
    get api_v1_shopkeeper_account_accounts_shopkeeper_url(@team_account, @team_accounts_shopkeeper),
      headers: @shopkeeper.create_new_auth_token

    assert_response :success
    assert_equal @team_accounts_shopkeeper.id.to_s, response.parsed_body["data"]["id"]
  end

  test "show returns error for personal account" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first

    get api_v1_shopkeeper_account_accounts_shopkeeper_url(@account, accounts_shopkeeper),
      headers: @shopkeeper.create_new_auth_token

    assert_response :unprocessable_entity
    assert_equal 422, response.parsed_body["code"]
    assert_equal I18n.t("api.shopkeeper.accounts_shopkeepers.require_non_personal_account"), response.parsed_body["error_message"]
  end

  test "update updates accounts_shopkeeper roles" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @team_account,
      shopkeeper: other_shopkeeper,
      member: true
    )

    patch api_v1_shopkeeper_account_accounts_shopkeeper_url(@team_account, accounts_shopkeeper),
      params: {accounts_shopkeeper: {admin: true, member: false}},
      headers: @shopkeeper.create_new_auth_token

    assert_response :success
    assert accounts_shopkeeper.reload.admin?
    assert_not accounts_shopkeeper.member?
  end

  test "update returns error for personal account" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first

    patch api_v1_shopkeeper_account_accounts_shopkeeper_url(@account, accounts_shopkeeper),
      params: {accounts_shopkeeper: {admin: false, member: true}},
      headers: @shopkeeper.create_new_auth_token

    assert_response :unprocessable_entity
  end

  test "update returns validation error when owner removes own admin" do
    patch api_v1_shopkeeper_account_accounts_shopkeeper_url(@team_account, @team_accounts_shopkeeper),
      params: {accounts_shopkeeper: {admin: false, member: true}},
      headers: @shopkeeper.create_new_auth_token

    assert_response :unprocessable_entity
    assert_equal 422, response.parsed_body["code"]
    assert response.parsed_body["error_message"].present?
  end

  test "update requires admin role" do
    other_shopkeeper = shopkeepers(:two)
    AccountsShopkeeper.create!(
      account: @team_account,
      shopkeeper: other_shopkeeper,
      member: true
    )

    patch api_v1_shopkeeper_account_accounts_shopkeeper_url(@team_account, @team_accounts_shopkeeper),
      params: {accounts_shopkeeper: {member: true}},
      headers: other_shopkeeper.create_new_auth_token

    assert_response :unauthorized
  end

  test "destroy removes accounts_shopkeeper" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @team_account,
      shopkeeper: other_shopkeeper,
      member: true
    )

    assert_difference "AccountsShopkeeper.count", -1 do
      delete api_v1_shopkeeper_account_accounts_shopkeeper_url(@team_account, accounts_shopkeeper),
        headers: @shopkeeper.create_new_auth_token
    end

    assert_response :success
  end

  test "destroy prevents account owner deletion" do
    delete api_v1_shopkeeper_account_accounts_shopkeeper_url(@team_account, @team_accounts_shopkeeper),
      headers: @shopkeeper.create_new_auth_token

    assert_response :unauthorized
    assert_equal 401, response.parsed_body["code"]
    assert_equal I18n.t("unauthorized"), response.parsed_body["error_message"]
  end

  test "destroy returns error for personal account" do
    accounts_shopkeeper = @account.accounts_shopkeepers.first

    delete api_v1_shopkeeper_account_accounts_shopkeeper_url(@account, accounts_shopkeeper),
      headers: @shopkeeper.create_new_auth_token

    assert_response :unprocessable_entity
  end

  test "destroy requires admin role" do
    other_shopkeeper = shopkeepers(:two)
    accounts_shopkeeper = AccountsShopkeeper.create!(
      account: @team_account,
      shopkeeper: other_shopkeeper,
      member: true
    )

    delete api_v1_shopkeeper_account_accounts_shopkeeper_url(@team_account, accounts_shopkeeper),
      headers: other_shopkeeper.create_new_auth_token

    assert_response :unauthorized
  end

  test "requires authentication" do
    get api_v1_shopkeeper_account_accounts_shopkeepers_url(@team_account)

    assert_response :unauthorized
  end
end
