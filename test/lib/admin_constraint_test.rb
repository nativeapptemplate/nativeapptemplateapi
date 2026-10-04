require "test_helper"

# Guards the Mission Control dashboard at /madmin/jobs (config/routes.rb)
class AdminConstraintTest < ActiveSupport::TestCase
  setup do
    @admin = AdminUser.create!(name: "Admin", email: "admin@example.com", password: "password")
    @constraint = AdminConstraint.new
  end

  test "matches a session of an existing admin" do
    assert @constraint.matches?(request_with(admin_user_id: @admin.id))
  end

  test "does not match without an admin session" do
    assert_not @constraint.matches?(request_with({}))
  end

  test "does not match once the admin is deleted" do
    @admin.destroy!

    assert_not @constraint.matches?(request_with(admin_user_id: @admin.id))
  end

  # Mission Control's own HTTP Basic auth would answer 401 to every admin, as
  # no credentials are configured; AdminConstraint is the guard instead
  test "Mission Control's built-in HTTP Basic auth is off" do
    assert_equal false, MissionControl::Jobs.http_basic_auth_enabled
  end

  private

  def request_with(session)
    Struct.new(:session).new(session)
  end
end
