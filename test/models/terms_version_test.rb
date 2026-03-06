require "test_helper"

class TermsVersionTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    terms_version = TermsVersion.new(
      version: 2,
      current_type: :current,
      published_at: Date.today,
      title: "Test Terms Version",
      description: "Test Description"
    )
    assert terms_version.valid?
  end

  test "should have current_type enum" do
    terms_version = TermsVersion.new(
      version: 2,
      current_type: :current,
      published_at: Date.today
    )

    assert terms_version.current?
    assert_not terms_version.uncurrent?

    terms_version.current_type = :uncurrent
    assert terms_version.uncurrent?
    assert_not terms_version.current?
  end

  test "current_version should return latest current version" do
    version = TermsVersion.current_version
    assert_not_nil version
    assert_kind_of Integer, version
  end

  test "current_version should return highest version number" do
    TermsVersion.create!(
      version: 10,
      current_type: :current,
      published_at: Date.today,
      title: "Version 10",
      description: "Test"
    )

    TermsVersion.create!(
      version: 15,
      current_type: :current,
      published_at: Date.today,
      title: "Version 15",
      description: "Test"
    )

    assert_equal 15, TermsVersion.current_version
  end

  test "current_version should only return current versions" do
    TermsVersion.create!(
      version: 20,
      current_type: :uncurrent,
      published_at: Date.today,
      title: "Uncurrent",
      description: "Test"
    )

    TermsVersion.create!(
      version: 5,
      current_type: :current,
      published_at: Date.today,
      title: "Current",
      description: "Test"
    )

    assert_equal 5, TermsVersion.current_version
  end

  test "should load from fixtures" do
    assert TermsVersion.count > 0

    terms_version = TermsVersion.first
    assert_not_nil terms_version
    assert_not_nil terms_version.version
    assert_not_nil terms_version.published_at
  end
end
