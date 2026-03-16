require "test_helper"

class AppVersionTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    app_version = AppVersion.new(
      platform: "ios",
      version: 2,
      current_type: :current,
      forced_update_type: :unforced_update,
      title: "Test Version",
      description: "Test Description"
    )
    assert app_version.valid?
  end

  test "should have current_type enum" do
    app_version = AppVersion.new(
      platform: "ios",
      version: 2,
      current_type: :current,
      forced_update_type: :unforced_update
    )

    assert app_version.current?
    assert_not app_version.uncurrent?

    app_version.current_type = :uncurrent
    assert app_version.uncurrent?
    assert_not app_version.current?
  end

  test "should have forced_update_type enum" do
    app_version = AppVersion.new(
      platform: "ios",
      version: 2,
      current_type: :current,
      forced_update_type: :forced_update
    )

    assert app_version.forced_update?
    assert_not app_version.unforced_update?

    app_version.forced_update_type = :unforced_update
    assert app_version.unforced_update?
    assert_not app_version.forced_update?
  end

  test "current_version should return latest current version for platform" do
    ios_version = AppVersion.current_version(platform: "ios")
    assert_not_nil ios_version
    assert_kind_of Integer, ios_version

    android_version = AppVersion.current_version(platform: "android")
    assert_not_nil android_version
    assert_kind_of Integer, android_version
  end

  test "current_version should return highest version for platform" do
    AppVersion.create!(
      platform: "ios",
      version: 10,
      current_type: :current,
      forced_update_type: :unforced_update,
      title: "Version 10",
      description: "Test"
    )

    AppVersion.create!(
      platform: "ios",
      version: 15,
      current_type: :current,
      forced_update_type: :unforced_update,
      title: "Version 15",
      description: "Test"
    )

    assert_equal 15, AppVersion.current_version(platform: "ios")
  end

  test "current_version should only return current versions" do
    AppVersion.create!(
      platform: "android",
      version: 20,
      current_type: :uncurrent,
      forced_update_type: :unforced_update,
      title: "Uncurrent",
      description: "Test"
    )

    AppVersion.create!(
      platform: "android",
      version: 5,
      current_type: :current,
      forced_update_type: :unforced_update,
      title: "Current",
      description: "Test"
    )

    assert_equal 5, AppVersion.current_version(platform: "android")
  end

  test "current_version returns nil for nonexistent platform" do
    assert_nil AppVersion.current_version(platform: "nonexistent")
  end

  test "current_version respects chained scopes" do
    version = AppVersion.forced_update.current_version(platform: "ios")
    assert_not_nil version

    # unforced_update scope should not find forced_update records
    AppVersion.where(platform: "ios").update_all(forced_update_type: :forced_update)
    version = AppVersion.unforced_update.current_version(platform: "ios")
    assert_nil version
  end

  test "should load from fixtures" do
    assert AppVersion.count > 0

    ios_version = AppVersion.find_by(platform: "ios")
    assert_not_nil ios_version

    android_version = AppVersion.find_by(platform: "android")
    assert_not_nil android_version
  end
end
