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

    # Returns a serialized response
    assert response.parsed_body["data"]
  end

  # devise_token_auth checks account_update_params in a before_action declared
  # before ours, so the extra keys must be permitted ahead of it
  test "updates a profile field without resending the email" do
    shopkeeper.create_default_account
    patch shopkeeper_registration_url, params: {time_zone: "Osaka"}, headers: shopkeeper.create_new_auth_token

    assert_response :success
    assert_equal "Osaka", shopkeeper.reload.time_zone
  end

  test "delete current shopkeeper" do
    assert_difference "Shopkeeper.count", -1 do
      delete shopkeeper_registration_url, headers: shopkeeper.create_new_auth_token
      assert_response :success
    end
  end

  test "delete current shopkeeper with item_tags" do
    shopkeeper.create_default_account
    account = shopkeeper.accounts.first

    ActsAsTenant.with_tenant(account) do
      shop = account.shops.create!(name: "Test Shop", created_by: shopkeeper)
      shop.item_tags.create!(name: "Buy milk", account: account, completed_by: shopkeeper)
    end

    assert_difference "Shopkeeper.count", -1 do
      delete shopkeeper_registration_url, headers: shopkeeper.create_new_auth_token
      assert_response :success
    end
  end

  # Owned accounts are destroyed with their shops, but a shop created in a team
  # someone else owns stays with that team and must outlive its creator.
  test "delete a shopkeeper who created a shop in another owner's team" do
    owner = shopkeepers(:two)
    owner.create_default_account
    team = Account.create!(name: "Team", owner: owner, personal: false)
    AccountsShopkeeper.create!(account: team, shopkeeper: owner, admin: true)
    AccountsShopkeeper.create!(account: team, shopkeeper: shopkeeper, member: true)
    shop = ActsAsTenant.with_tenant(team) { team.shops.create!(name: "Member's shop", created_by: shopkeeper) }

    assert_difference "Shopkeeper.count", -1 do
      delete shopkeeper_registration_url, headers: shopkeeper.create_new_auth_token
      assert_response :success
    end

    shop = ActsAsTenant.without_tenant { Shop.find(shop.id) }
    assert_nil shop.created_by_id
    assert_equal team, shop.account

    # The team can keep editing the orphaned shop (the account prefix selects the team)
    patch "/#{team.id}/api/v1/shopkeeper/shops/#{shop.id}", params: {shop: {name: "Renamed"}},
      headers: owner.create_new_auth_token
    assert_response :success
    assert_equal "Renamed", ActsAsTenant.without_tenant { shop.reload.name }
  end

  test "a shop still needs a creator when it is created" do
    account = Account.create!(name: "Solo", owner: shopkeeper, personal: false)

    shop = ActsAsTenant.with_tenant(account) { account.shops.new(name: "No creator") }

    assert_not shop.valid?
    assert_includes shop.errors[:created_by], "must exist"
  end

  def shopkeeper
    @shopkeeper ||= shopkeepers(:one)
  end
end
