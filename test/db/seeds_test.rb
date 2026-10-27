require "test_helper"

# bin/rails db:prepare (run by bin/docker-entrypoint on every boot) loads
# db/seeds.rb only when it has just created the schema: the first deploy, or a
# demo database that was reset. Without the production fixtures then, sign-up
# fails with a 500 (no current PrivacyVersion) and GET /permissions with a 404
# (no Role), as happened on the demo on 2026-10-27.
class SeedsTest < ActiveSupport::TestCase
  SEEDS = Rails.root.join("db/seeds.rb")

  setup do
    [RolesPermission, Role, Permission, AppVersion, PrivacyVersion, TermsVersion].each(&:delete_all)
  end

  test "production seeds load the rows the app cannot run without" do
    load_seeds_in("production")

    # db/fixtures/production/02_roles.rb and 01_permissions.rb
    assert_equal %w[admin member], Role.order(:position).pluck(:tag)
    assert_equal 6, Permission.count
    # 03_roles_permissions.rb: admin has all 6, member all but delete_shops and update_organizations
    assert_equal 6, Role.find_by!(tag: "admin").permissions.count
    assert_equal 4, Role.find_by!(tag: "member").permissions.count
    # db/data/*.csv: version 1 is current on both platforms
    assert_equal 1, AppVersion.current_version(platform: "ios")
    assert_equal 1, AppVersion.current_version(platform: "android")
    assert_equal 1, PrivacyVersion.current_version
    assert_equal 1, TermsVersion.current_version
  end

  # Development loads its own fixtures (sample shopkeepers and shops) with
  # bin/setup's db:seed_fu, and the tests load db/fixtures/test in setup
  test "other environments seed nothing" do
    %w[development test].each do |env|
      load_seeds_in(env)

      assert_equal 0, Role.count, "db/seeds.rb seeded roles in #{env}"
      assert_nil PrivacyVersion.current_version, "db/seeds.rb seeded a privacy version in #{env}"
    end
  end

  private

  def load_seeds_in(env)
    quiet = SeedFu.quiet
    SeedFu.quiet = true
    Rails.stub(:env, ActiveSupport::EnvironmentInquirer.new(env)) { load SEEDS }
  ensure
    SeedFu.quiet = quiet
  end
end
