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

  test "should create default item tags after creation" do
    ActsAsTenant.with_tenant(@account) do
      shop = @account.shops.create!(name: "Test Shop", created_by: @shopkeeper)
      expected_count = ConfigSettings.item_tag.default_count
      assert_equal expected_count, shop.item_tags.count
    end
  end

  test "default item tags should have correct queue numbers" do
    ActsAsTenant.with_tenant(@account) do
      shop = @account.shops.create!(name: "Test Shop", created_by: @shopkeeper)
      item_tags = shop.item_tags.sorted

      # Queue numbers are formatted based on ConfigSettings.item_tag.default_queue_number_length
      # which defaults to 4, making the format "A001" not "A01"
      assert_equal "A001", item_tags.first.queue_number
      assert item_tags.all? { |tag| tag.queue_number.start_with?("A") }
    end
  end

  test "should not create default item tags if item tags already exist" do
    ActsAsTenant.with_tenant(@account) do
      shop = @account.shops.create!(name: "Test Shop", created_by: @shopkeeper)
      initial_count = shop.item_tags.count

      # Manually trigger the callback
      shop.send(:create_default_item_tags!)

      assert_equal initial_count, shop.item_tags.reload.count
    end
  end

  test "should destroy associated item tags" do
    ActsAsTenant.with_tenant(@account) do
      shop = @account.shops.create!(name: "Test Shop", created_by: @shopkeeper)
      item_tag_count = shop.item_tags.count

      assert_difference "ItemTag.count", -item_tag_count do
        shop.destroy
      end
    end
  end

  test "latest_completed_item_tag returns most recently completed tag" do
    ActsAsTenant.with_tenant(@account) do
      shop = @account.shops.create!(name: "Test Shop", created_by: @shopkeeper)
      item_tag1 = shop.item_tags.first
      item_tag2 = shop.item_tags.second

      item_tag1.complete_tag!(@shopkeeper)
      sleep 0.01 # Ensure different timestamps
      item_tag2.complete_tag!(@shopkeeper)

      assert_equal item_tag2, shop.latest_completed_item_tag
    end
  end

  test "latest_completed_item_tag returns nil if no completed tags" do
    ActsAsTenant.with_tenant(@account) do
      shop = @account.shops.create!(name: "Test Shop", created_by: @shopkeeper)
      assert_nil shop.latest_completed_item_tag
    end
  end

  test "reset! resets all item tags" do
    ActsAsTenant.with_tenant(@account) do
      shop = @account.shops.create!(name: "Test Shop", created_by: @shopkeeper)
      item_tag1 = shop.item_tags.first
      item_tag2 = shop.item_tags.second

      item_tag1.complete_tag!(@shopkeeper)
      item_tag2.complete_tag!(@shopkeeper)

      assert item_tag1.completed?
      assert item_tag2.completed?

      shop.reset!

      assert item_tag1.reload.idled?
      assert item_tag2.reload.idled?
      assert_nil item_tag1.completed_at
      assert_nil item_tag2.completed_at
    end
  end
end
