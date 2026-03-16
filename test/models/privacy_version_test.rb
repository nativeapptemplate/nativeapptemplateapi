require "test_helper"

class PrivacyVersionTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    privacy_version = PrivacyVersion.new(
      version: 2,
      current_type: :current,
      published_at: Date.today,
      title: "Test Privacy Version",
      description: "Test Description"
    )
    assert privacy_version.valid?
  end

  test "should have current_type enum" do
    privacy_version = PrivacyVersion.new(
      version: 2,
      current_type: :current,
      published_at: Date.today
    )

    assert privacy_version.current?
    assert_not privacy_version.uncurrent?

    privacy_version.current_type = :uncurrent
    assert privacy_version.uncurrent?
    assert_not privacy_version.current?
  end

  test "current_version should return latest current version" do
    version = PrivacyVersion.current_version
    assert_not_nil version
    assert_kind_of Integer, version
  end

  test "current_version should return highest version number" do
    PrivacyVersion.create!(
      version: 10,
      current_type: :current,
      published_at: Date.today,
      title: "Version 10",
      description: "Test"
    )

    PrivacyVersion.create!(
      version: 15,
      current_type: :current,
      published_at: Date.today,
      title: "Version 15",
      description: "Test"
    )

    assert_equal 15, PrivacyVersion.current_version
  end

  test "current_version should only return current versions" do
    PrivacyVersion.create!(
      version: 20,
      current_type: :uncurrent,
      published_at: Date.today,
      title: "Uncurrent",
      description: "Test"
    )

    PrivacyVersion.create!(
      version: 5,
      current_type: :current,
      published_at: Date.today,
      title: "Current",
      description: "Test"
    )

    assert_equal 5, PrivacyVersion.current_version
  end

  test "current_version returns nil when no current version exists" do
    PrivacyVersion.update_all(current_type: :uncurrent)
    assert_nil PrivacyVersion.current_version
  end

  test "should load from fixtures" do
    assert PrivacyVersion.count > 0

    privacy_version = PrivacyVersion.first
    assert_not_nil privacy_version
    assert_not_nil privacy_version.version
    assert_not_nil privacy_version.published_at
  end
end
