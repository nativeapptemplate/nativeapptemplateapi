require "test_helper"

class ApplicationPushDeviceTest < ActiveSupport::TestCase
  setup do
    @shopkeeper = shopkeepers(:one)
  end

  test "is valid with token + platform + owner" do
    device = ApplicationPushDevice.new(owner: @shopkeeper, token: "abc123", platform: "apple")
    assert device.valid?
  end

  test "requires token" do
    device = ApplicationPushDevice.new(owner: @shopkeeper, platform: "apple")
    assert_not device.valid?
    assert_includes device.errors[:token], "can't be blank"
  end

  test "requires platform" do
    device = ApplicationPushDevice.new(owner: @shopkeeper, token: "abc123")
    assert_not device.valid?
    assert_includes device.errors[:platform], "is not included in the list"
  end

  test "rejects unknown platform" do
    device = ApplicationPushDevice.new(owner: @shopkeeper, token: "abc123", platform: "blackberry")
    assert_not device.valid?
    assert_includes device.errors[:platform], "is not included in the list"
  end

  test "enforces uniqueness scoped to platform" do
    ApplicationPushDevice.create!(owner: @shopkeeper, token: "abc123", platform: "apple")
    duplicate = ApplicationPushDevice.new(owner: @shopkeeper, token: "abc123", platform: "apple")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:token], "has already been taken"
  end

  test "allows same token across different platforms" do
    ApplicationPushDevice.create!(owner: @shopkeeper, token: "abc123", platform: "apple")
    other = ApplicationPushDevice.new(owner: @shopkeeper, token: "abc123", platform: "google")
    assert other.valid?
  end

  test "sets last_active_at on create when not provided" do
    freeze_time do
      device = ApplicationPushDevice.create!(owner: @shopkeeper, token: "abc123", platform: "apple")
      assert_equal Time.current, device.last_active_at
    end
  end

  test "preserves explicit last_active_at on create" do
    explicit = 1.day.ago.beginning_of_minute
    device = ApplicationPushDevice.create!(owner: @shopkeeper, token: "abc123", platform: "apple", last_active_at: explicit)
    assert_equal explicit, device.last_active_at
  end

  test "active scope excludes devices stale > 90 days" do
    fresh = ApplicationPushDevice.create!(owner: @shopkeeper, token: "fresh", platform: "apple", last_active_at: 1.day.ago)
    stale = ApplicationPushDevice.create!(owner: @shopkeeper, token: "stale", platform: "apple", last_active_at: 100.days.ago)
    active = ApplicationPushDevice.active
    assert_includes active, fresh
    assert_not_includes active, stale
  end

  test "is destroyed when shopkeeper is destroyed" do
    ApplicationPushDevice.create!(owner: @shopkeeper, token: "abc123", platform: "apple")
    assert_difference -> { ApplicationPushDevice.count }, -1 do
      @shopkeeper.destroy
    end
  end
end
