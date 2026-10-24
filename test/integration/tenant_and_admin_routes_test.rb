require "test_helper"

class TenantAndAdminRoutesTest < ActionDispatch::IntegrationTest
  # AccountMiddleware selects any existing account from the URL without
  # checking membership; Api::V1::Shopkeeper::BaseController then refuses a
  # shopkeeper who isn't a member (403 not_account_member).
  test "another tenant's account id in the URL gets 403 and no data" do
    outsider = shopkeepers(:one)
    outsider.create_default_account
    owner = shopkeepers(:two)
    owner.create_default_account
    other_account = owner.accounts.first

    get "/#{other_account.id}/api/v1/shopkeeper/shops", headers: outsider.create_new_auth_token

    assert_response :forbidden
    assert_equal 403, response.parsed_body["code"]
    assert_equal "not_account_member", response.parsed_body["error_code"]
    assert_nil response.parsed_body["data"]
  end

  test "a member reaches their account through the URL prefix" do
    owner = shopkeepers(:two)
    owner.create_default_account
    account = owner.accounts.first

    get "/#{account.id}/api/v1/shopkeeper/shops", headers: owner.create_new_auth_token

    assert_response :success
    assert_equal account.shops.order(:name).pluck(:id), response.parsed_body["data"].pluck("id")
  end

  # AdminConstraint guards the Mission Control (Solid Queue) dashboard
  test "/madmin/jobs is hidden from guests" do
    get "/madmin/jobs"

    assert_response :not_found
  end

  test "/madmin/jobs is hidden again once the admin is deleted" do
    admin = sign_in_admin
    admin.destroy!

    get "/madmin/jobs"

    assert_response :not_found
  end

  # Mission Control's buttons (retry, discard) are forms posted with the
  # admin's session cookie, so they need the authenticity token check that
  # ActionController::API leaves out
  test "/madmin/jobs refuses a form post without the authenticity token" do
    sign_in_admin
    ActionController::Base.allow_forgery_protection = true

    post "/madmin/jobs/applications/nativeapptemplateapi/jobs/bulk_discards"

    assert_response :unprocessable_content
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  private

  def sign_in_admin
    admin = AdminUser.create!(name: "Admin", email: "admin@example.com", password: "password")
    post admin_session_path, params: {email: admin.email, password: "password"}
    admin
  end
end
