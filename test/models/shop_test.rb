require "test_helper"

class ShopTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
  end

  test "should be valid with valid attributes" do
    shop = @account.shops.new(name: "Test Shop", created_by: @shopkeeper)
    assert shop.valid?
  end

  test "should require name" do
    shop = @account.shops.new(created_by: @shopkeeper)
    assert_not shop.valid?
    assert_includes shop.errors[:name], "can't be blank"
  end

  test "should belong to account" do
    shop = @account.shops.create!(name: "Test Shop", created_by: @shopkeeper)
    assert_equal @account, shop.account
  end

  test "should belong to created_by shopkeeper" do
    shop = @account.shops.create!(name: "Test Shop", created_by: @shopkeeper)
    assert_equal @shopkeeper, shop.created_by
  end

  test "creating shop creates exactly one sample item tag" do
    ActsAsTenant.with_tenant(@account) do
      shop = @account.shops.create!(name: "Test Shop", created_by: @shopkeeper)
      assert_equal 1, shop.item_tags.count

      sample = shop.item_tags.first
      assert_equal "Sample", sample.name
      assert sample.description.start_with?("This is a sample")
      assert_equal 1, sample.position
      assert sample.idled?
    end
  end

  test "sample item tag failure does not prevent shop creation" do
    ActsAsTenant.with_tenant(@account) do
      shop = @account.shops.new(name: "Test Shop", created_by: @shopkeeper)

      # Stub the association to raise during the after_create callback
      shop.define_singleton_method(:item_tags) do
        raise StandardError, "boom"
      end

      assert_difference "Shop.count", 1 do
        shop.save!
      end

      assert_predicate shop, :persisted?
    end
  end

  test "should destroy associated item tags" do
    ActsAsTenant.with_tenant(@account) do
      shop = @account.shops.create!(name: "Test Shop", created_by: @shopkeeper)
      item_tag_count = shop.item_tags.count
      assert item_tag_count > 0

      assert_difference "ItemTag.count", -item_tag_count do
        shop.destroy
      end
    end
  end

  # The apps send Rails time zone names (ActiveSupport::TimeZone#name)
  test "should accept every Rails time zone name" do
    shop = @account.shops.new(name: "Test Shop", created_by: @shopkeeper)
    ActiveSupport::TimeZone.all.map(&:name).each do |time_zone|
      shop.time_zone = time_zone
      assert shop.valid?, time_zone
    end
  end

  # ActiveSupport::TimeZone["Asia/Tokyo"] finds a zone, but "Asia/Tokyo" is an
  # IANA id, not one of the Rails names the apps send and list, so reject it
  test "should reject a time zone that is not a Rails time zone name" do
    shop = @account.shops.new(name: "Test Shop", created_by: @shopkeeper)
    ["Bogus", "", "Asia/Tokyo"].each do |time_zone|
      shop.time_zone = time_zone
      assert_not shop.valid?, time_zone
      assert_includes shop.errors[:time_zone], "is not included in the list"
    end
  end

  # A stored zone that is not a Rails name must not block unrelated updates
  test "should not revalidate an unchanged time zone" do
    shop = @account.shops.create!(name: "Test Shop", created_by: @shopkeeper)
    shop.update_column(:time_zone, "Asia/Tokyo")
    shop.name = "Renamed"
    assert shop.valid?
  end
end
