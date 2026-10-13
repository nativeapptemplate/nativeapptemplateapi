require "test_helper"

# A client keeps the current organization's id in every API path
# (/<account uuid>/api/...). When that organization is deleted, or the
# shopkeeper is removed from it, the client must be able to tell those cases
# apart from other errors, so it can switch to the personal organization
# instead of signing the shopkeeper out:
#
#   deleted organization            -> 404 {code, error_code: "account_not_found", error_message}
#   signed in, no longer a member   -> 403 {code, error_code: "not_account_member", error_message}
#
# Everything else is unchanged: Pundit denials inside an organization the
# shopkeeper belongs to stay 401 with error_message, and devise_token_auth's
# invalid-token 401 keeps its {"errors": [...]} body.
class AccountMembershipErrorsTest < ActionDispatch::IntegrationTest
  # Account ids are Postgres gen_random_uuid() values; this one never exists
  MISSING_ACCOUNT_ID = "00000000-0000-0000-0000-000000000000"

  # The wording of the contract (org-membership-contract.md)
  ACCOUNT_NOT_FOUND = {
    en: "This organization no longer exists.",
    ja: "この組織は削除されました。"
  }.freeze
  NOT_ACCOUNT_MEMBER = {
    en: "You are no longer a member of this organization.",
    ja: "この組織のメンバーではなくなりました。"
  }.freeze

  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @owner = shopkeepers(:two)
    @owner.create_default_account
    # A team organization the shopkeeper was removed from (or never joined)
    @team = Account.create!(name: "Team", owner: @owner, personal: false)
    @team.accounts_shopkeepers.create!(shopkeeper: @owner, admin: true)
  end

  # --- Deleted organization -------------------------------------------------

  test "a deleted organization answers 404 account_not_found for a signed-in GET without Content-Type" do
    get "/#{MISSING_ACCOUNT_ID}/api/v1/shopkeeper/permissions", headers: @shopkeeper.create_new_auth_token

    assert_account_error 404, "account_not_found", ACCOUNT_NOT_FOUND[:en]
  end

  test "a deleted organization answers 404 account_not_found for a JSON request" do
    patch "/#{MISSING_ACCOUNT_ID}/api/v1/shopkeeper/shops/#{MISSING_ACCOUNT_ID}",
      params: {shop: {name: "x"}}.to_json,
      headers: @shopkeeper.create_new_auth_token.merge("Content-Type" => "application/json", "Accept" => "application/json")

    assert_account_error 404, "account_not_found", ACCOUNT_NOT_FOUND[:en]
  end

  # Android sends only the JSON:API media type
  test "a deleted organization answers 404 account_not_found for Accept application/vnd.api+json" do
    get "/#{MISSING_ACCOUNT_ID}/api/v1/shopkeeper/shops",
      headers: @shopkeeper.create_new_auth_token.merge("Accept" => "application/vnd.api+json")

    assert_account_error 404, "account_not_found", ACCOUNT_NOT_FOUND[:en]
  end

  test "an organization deleted after the client stored it answers 404 account_not_found" do
    team_id = @team.id
    ActsAsTenant.without_tenant { @team.destroy! }

    get "/#{team_id}/api/v1/shopkeeper/shops", headers: @owner.create_new_auth_token

    assert_account_error 404, "account_not_found", ACCOUNT_NOT_FOUND[:en]
  end

  test "a deleted organization answers 404 account_not_found even without a valid token" do
    get "/#{MISSING_ACCOUNT_ID}/api/v1/shopkeeper/shops"

    assert_account_error 404, "account_not_found", ACCOUNT_NOT_FOUND[:en]
  end

  test "account_not_found uses the signed-in shopkeeper's saved locale" do
    @shopkeeper.update!(locale: "ja")

    get "/#{MISSING_ACCOUNT_ID}/api/v1/shopkeeper/shops",
      headers: @shopkeeper.create_new_auth_token.merge("Accept-Language" => "en")

    assert_account_error 404, "account_not_found", ACCOUNT_NOT_FOUND[:ja]
  end

  test "account_not_found uses Accept-Language without a signed-in shopkeeper" do
    get "/#{MISSING_ACCOUNT_ID}/api/v1/shopkeeper/shops", headers: {"Accept-Language" => "ja-JP"}

    assert_account_error 404, "account_not_found", ACCOUNT_NOT_FOUND[:ja]
  end

  test "a deleted organization in a non-API path still redirects to the root" do
    get "/#{MISSING_ACCOUNT_ID}/shopkeeper_auth/confirmation_result"

    assert_response :found
    assert_equal "/", response.headers["Location"]
  end

  # --- Signed in, not a member ---------------------------------------------

  test "permissions in an organization the shopkeeper left answers 403 not_account_member" do
    get "/#{@team.id}/api/v1/shopkeeper/permissions", headers: @shopkeeper.create_new_auth_token

    assert_account_error 403, "not_account_member", NOT_ACCOUNT_MEMBER[:en]
  end

  test "shops in an organization the shopkeeper left answers 403 not_account_member" do
    get "/#{@team.id}/api/v1/shopkeeper/shops", headers: @shopkeeper.create_new_auth_token

    assert_account_error 403, "not_account_member", NOT_ACCOUNT_MEMBER[:en]
    assert_nil response.parsed_body["data"]
  end

  test "the accounts list under an organization the shopkeeper left answers 403 not_account_member" do
    get "/#{@team.id}/api/v1/shopkeeper/accounts", headers: @shopkeeper.create_new_auth_token

    assert_account_error 403, "not_account_member", NOT_ACCOUNT_MEMBER[:en]
  end

  test "an invitation looked up under an organization the shopkeeper left answers 403 not_account_member" do
    invitation = AccountsInvitation.create!(account: @owner.accounts.personal.first,
      name: "Invited", email: @shopkeeper.email, member: true)

    get "/#{@team.id}/api/v1/shopkeeper/accounts_invitations/#{invitation.token}",
      headers: @shopkeeper.create_new_auth_token

    assert_account_error 403, "not_account_member", NOT_ACCOUNT_MEMBER[:en]
  end

  test "not_account_member uses the shopkeeper's saved locale over Accept-Language" do
    @shopkeeper.update!(locale: "ja")

    get "/#{@team.id}/api/v1/shopkeeper/shops",
      headers: @shopkeeper.create_new_auth_token.merge("Accept-Language" => "en")

    assert_account_error 403, "not_account_member", NOT_ACCOUNT_MEMBER[:ja]
  end

  test "not_account_member is English for a shopkeeper whose saved locale is en" do
    get "/#{@team.id}/api/v1/shopkeeper/shops",
      headers: @shopkeeper.create_new_auth_token.merge("Accept-Language" => "ja")

    assert_account_error 403, "not_account_member", NOT_ACCOUNT_MEMBER[:en]
  end

  # --- Unchanged ------------------------------------------------------------

  test "a real Pundit denial inside an organization the shopkeeper belongs to stays 401" do
    # AccountPolicy#update? requires admin; the shopkeeper is a plain member
    @team.accounts_shopkeepers.create!(shopkeeper: @shopkeeper, admin: false, member: true)

    patch "/#{@team.id}/api/v1/shopkeeper/accounts/#{@team.id}",
      params: {account: {name: "Renamed"}},
      headers: @shopkeeper.create_new_auth_token

    assert_response :unauthorized
    assert_equal({"code" => 401, "error_message" => I18n.t("unauthorized", locale: :en)}, response.parsed_body)
  end

  test "a member still reaches the organization" do
    @team.accounts_shopkeepers.create!(shopkeeper: @shopkeeper, admin: false, member: true)

    get "/#{@team.id}/api/v1/shopkeeper/shops", headers: @shopkeeper.create_new_auth_token

    assert_response :success
  end

  test "an invalid token in an existing organization keeps devise_token_auth's 401" do
    headers = @shopkeeper.create_new_auth_token.merge("access-token" => "wrong")

    get "/#{@team.id}/api/v1/shopkeeper/shops", headers: headers

    assert_response :unauthorized
    assert response.parsed_body["errors"].present?
    assert_nil response.parsed_body["error_code"]
    assert_nil response.parsed_body["error_message"]
  end

  private

  def assert_account_error(status, error_code, message)
    assert_response status
    assert_equal "application/json", response.media_type
    assert_equal({"code" => status, "error_code" => error_code, "error_message" => message}, response.parsed_body)
  end
end
