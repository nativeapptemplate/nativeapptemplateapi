require "test_helper"

class DeviceTest < ActiveSupport::TestCase
  setup do
    @shopkeeper = shopkeepers(:one)
  end

  test "is valid with token + platform + shopkeeper" do
    device = Device.new(shopkeeper: @shopkeeper, token: "abc123", platform: "ios")
    assert device.valid?
  end

  test "requires token" do
    device = Device.new(shopkeeper: @shopkeeper, platform: "ios")
    assert_not device.valid?
    assert_includes device.errors[:token], "can't be blank"
  end

  test "requires platform" do
    device = Device.new(shopkeeper: @shopkeeper, token: "abc123")
    assert_not device.valid?
    assert_includes device.errors[:platform], "can't be blank"
  end

  test "rejects unknown platform" do
    assert_raises(ArgumentError) do
      Device.new(shopkeeper: @shopkeeper, token: "abc123", platform: "blackberry")
    end
  end

  test "enforces uniqueness scoped to platform" do
    Device.create!(shopkeeper: @shopkeeper, token: "abc123", platform: "ios")
    duplicate = Device.new(shopkeeper: @shopkeeper, token: "abc123", platform: "ios")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:token], "has already been taken"
  end

  test "allows same token across different platforms" do
    Device.create!(shopkeeper: @shopkeeper, token: "abc123", platform: "ios")
    other = Device.new(shopkeeper: @shopkeeper, token: "abc123", platform: "android")
    assert other.valid?
  end

  test "sets last_active_at on create when not provided" do
    freeze_time do
      device = Device.create!(shopkeeper: @shopkeeper, token: "abc123", platform: "ios")
      assert_equal Time.current, device.last_active_at
    end
  end

  test "preserves explicit last_active_at on create" do
    explicit = 1.day.ago.beginning_of_minute
    device = Device.create!(shopkeeper: @shopkeeper, token: "abc123", platform: "ios", last_active_at: explicit)
    assert_equal explicit, device.last_active_at
  end

  test "active scope excludes devices stale > 90 days" do
    fresh = Device.create!(shopkeeper: @shopkeeper, token: "fresh", platform: "ios", last_active_at: 1.day.ago)
    stale = Device.create!(shopkeeper: @shopkeeper, token: "stale", platform: "ios", last_active_at: 100.days.ago)
    active = Device.active
    assert_includes active, fresh
    assert_not_includes active, stale
  end

  test "is destroyed when shopkeeper is destroyed" do
    Device.create!(shopkeeper: @shopkeeper, token: "abc123", platform: "ios")
    assert_difference -> { Device.count }, -1 do
      @shopkeeper.destroy
    end
  end
end
