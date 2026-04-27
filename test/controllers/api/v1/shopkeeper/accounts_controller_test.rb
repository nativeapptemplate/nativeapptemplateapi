require "test_helper"

class Api::V1::Shopkeeper::AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first

    @team_account = Account.create!(name: "Team Account", owner: @shopkeeper, personal: false)
    AccountsShopkeeper.create!(
      account: @team_account,
      shopkeeper: @shopkeeper,
      admin: true
    )
  end

  test "index returns current shopkeeper accounts" do
    get api_v1_shopkeeper_accounts_url, headers: @shopkeeper.create_new_auth_token
    assert_response :success
    assert_includes response.parsed_body["data"].map { |t| t["attributes"]["name"] }, @account.name
  end

  test "show returns account details" do
    get api_v1_shopkeeper_account_url(@team_account), headers: @shopkeeper.create_new_auth_token
    assert_response :success
    assert_equal @team_account.id.to_s, response.parsed_body["data"]["id"]
  end

  test "create returns validation error with blank name" do
    post api_v1_shopkeeper_accounts_url,
      params: {account: {name: ""}},
      headers: @shopkeeper.create_new_auth_token

    assert_response :unprocessable_entity
    assert_equal 422, response.parsed_body["code"]
    assert_not_nil response.parsed_body["error_message"]
  end

  test "create creates a new account" do
    assert_difference "Account.count", 1 do
      post api_v1_shopkeeper_accounts_url,
        params: {account: {name: "New Account"}},
        headers: @shopkeeper.create_new_auth_token
    end

    assert_response :created
  end

  test "update returns validation error with blank name" do
    patch api_v1_shopkeeper_account_url(@team_account),
      params: {account: {name: ""}},
      headers: @shopkeeper.create_new_auth_token

    assert_response :unprocessable_entity
    assert_equal 422, response.parsed_body["code"]
    assert_not_nil response.parsed_body["error_message"]
  end

  test "update requires admin role" do
    other_shopkeeper = shopkeepers(:two)
    AccountsShopkeeper.create!(
      account: @team_account,
      shopkeeper: other_shopkeeper,
      member: true
    )

    patch api_v1_shopkeeper_account_url(@team_account),
      params: {account: {name: "Updated"}},
      headers: other_shopkeeper.create_new_auth_token

    assert_response :unauthorized
  end

  test "update succeeds for admin" do
    patch api_v1_shopkeeper_account_url(@team_account),
      params: {account: {name: "Updated Name"}},
      headers: @shopkeeper.create_new_auth_token

    assert_response :success
    assert_equal "Updated Name", @team_account.reload.name
  end

  test "destroy requires owner" do
    other_shopkeeper = shopkeepers(:two)
    AccountsShopkeeper.create!(
      account: @team_account,
      shopkeeper: other_shopkeeper,
      admin: true
    )

    delete api_v1_shopkeeper_account_url(@team_account),
      headers: other_shopkeeper.create_new_auth_token

    assert_response :unauthorized
  end

  test "destroy prevents personal account deletion" do
    delete api_v1_shopkeeper_account_url(@account),
      headers: @shopkeeper.create_new_auth_token

    assert_response :unprocessable_entity
    assert_equal 422, response.parsed_body["code"]
    assert_equal I18n.t("api.shopkeeper.accounts.personal.cannot_delete"), response.parsed_body["error_message"]
  end

  test "destroy succeeds for owner" do
    assert_difference "Account.count", -1 do
      delete api_v1_shopkeeper_account_url(@team_account),
        headers: @shopkeeper.create_new_auth_token
    end

    assert_response :success
  end

  test "requires authentication" do
    get api_v1_shopkeeper_accounts_url

    assert_response :unauthorized
  end
end
