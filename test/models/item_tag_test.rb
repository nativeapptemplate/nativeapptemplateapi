require "test_helper"

class ItemTagTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
    @shop = @account.shops.first
  end

  test "should be valid with valid attributes" do
    ActsAsTenant.with_tenant(@account) do
      item_tag = @shop.item_tags.new(queue_number: "B01", account: @account)
      assert item_tag.valid?
    end
  end

  test "should require queue_number" do
    ActsAsTenant.with_tenant(@account) do
      item_tag = @shop.item_tags.new(account: @account)
      assert_not item_tag.valid?
      assert_includes item_tag.errors[:queue_number], "can't be blank"
    end
  end

  test "should validate queue_number format" do
    ActsAsTenant.with_tenant(@account) do
      # Valid formats
      assert @shop.item_tags.new(queue_number: "A1", account: @account).valid?
      assert @shop.item_tags.new(queue_number: "AB", account: @account).valid?
      assert @shop.item_tags.new(queue_number: "A01", account: @account).valid?
      assert @shop.item_tags.new(queue_number: "ABC12", account: @account).valid?

      # Invalid formats
      item_tag = @shop.item_tags.new(queue_number: "A", account: @account) # Too short
      assert_not item_tag.valid?

      item_tag = @shop.item_tags.new(queue_number: "ABCDEF", account: @account) # Too long
      assert_not item_tag.valid?

      item_tag = @shop.item_tags.new(queue_number: "A@1", account: @account) # Invalid character
      assert_not item_tag.valid?
    end
  end

  test "should validate uniqueness of queue_number within shop" do
    ActsAsTenant.with_tenant(@account) do
      @shop.item_tags.create!(queue_number: "B01", account: @account)
      duplicate = @shop.item_tags.new(queue_number: "B01", account: @account)

      assert_not duplicate.valid?
      assert_includes duplicate.errors[:queue_number], I18n.t("activerecord.errors.models.item_tag.attributes.queue_number.uniqueness_error")
    end
  end

  test "should allow same queue_number in different shops" do
    ActsAsTenant.with_tenant(@account) do
      shop2 = @account.shops.create!(name: "Shop 2", created_by: @shopkeeper)

      @shop.item_tags.create!(queue_number: "B01", account: @account)
      item_tag2 = shop2.item_tags.create!(queue_number: "B01", account: @account)

      assert item_tag2.valid?
    end
  end

  test "should belong to shop" do
    ActsAsTenant.with_tenant(@account) do
      item_tag = @shop.item_tags.first
      assert_equal @shop, item_tag.shop
    end
  end

  test "should belong to account" do
    ActsAsTenant.with_tenant(@account) do
      item_tag = @shop.item_tags.first
      assert_equal @account, item_tag.account
    end
  end

  test "should have initial state of idled" do
    ActsAsTenant.with_tenant(@account) do
      item_tag = @shop.item_tags.create!(queue_number: "B01", account: @account)
      assert item_tag.idled?
    end
  end

  test "should have initial scan_state of unscanned" do
    ActsAsTenant.with_tenant(@account) do
      item_tag = @shop.item_tags.create!(queue_number: "B01", account: @account)
      assert item_tag.unscanned?
    end
  end

  test "complete! transitions from idled to completed" do
    ActsAsTenant.with_tenant(@account) do
      item_tag = @shop.item_tags.first
      assert item_tag.idled?

      item_tag.complete!

      assert item_tag.completed?
    end
  end

  test "idle! transitions from completed to idled" do
    ActsAsTenant.with_tenant(@account) do
      item_tag = @shop.item_tags.first
      item_tag.complete!

      assert item_tag.completed?

      item_tag.idle!

      assert item_tag.idled?
    end
  end

  test "scan! transitions from unscanned to scanned" do
    ActsAsTenant.with_tenant(@account) do
      item_tag = @shop.item_tags.first
      assert item_tag.unscanned?

      item_tag.scan!

      assert item_tag.scanned?
    end
  end

  test "unscan! transitions to unscanned" do
    ActsAsTenant.with_tenant(@account) do
      item_tag = @shop.item_tags.first
      item_tag.scan!

      assert item_tag.scanned?

      item_tag.unscan!

      assert item_tag.unscanned?
    end
  end

  test "scan_tag! sets customer_read_at and scans" do
    ActsAsTenant.with_tenant(@account) do
      item_tag = @shop.item_tags.first
      assert_nil item_tag.customer_read_at

      item_tag.scan_tag!

      assert_not_nil item_tag.customer_read_at
      assert item_tag.scanned?
    end
  end

  test "scan_tag! does nothing if cannot scan" do
    ActsAsTenant.with_tenant(@account) do
      item_tag = @shop.item_tags.first
      item_tag.scan!

      assert item_tag.scanned?

      old_time = item_tag.customer_read_at
      item_tag.scan_tag!

      assert_equal old_time, item_tag.customer_read_at
    end
  end

  test "complete_tag! sets completed_by and completed_at and completes" do
    ActsAsTenant.with_tenant(@account) do
      item_tag = @shop.item_tags.first
      assert_nil item_tag.completed_by
      assert_nil item_tag.completed_at

      item_tag.complete_tag!(@shopkeeper)

      assert_equal @shopkeeper, item_tag.completed_by
      assert_not_nil item_tag.completed_at
      assert item_tag.completed?
      assert_equal false, item_tag.already_completed
    end
  end

  test "complete_tag! does nothing if cannot complete" do
    ActsAsTenant.with_tenant(@account) do
      item_tag = @shop.item_tags.first
      item_tag.complete_tag!(@shopkeeper)

      assert item_tag.completed?

      item_tag.complete_tag!(shopkeepers(:two))

      assert_equal @shopkeeper, item_tag.completed_by
    end
  end

  test "reset! clears all completion data and resets states" do
    ActsAsTenant.with_tenant(@account) do
      item_tag = @shop.item_tags.first
      item_tag.scan_tag!
      item_tag.complete_tag!(@shopkeeper)

      assert item_tag.completed?
      assert item_tag.scanned?
      assert_not_nil item_tag.customer_read_at
      assert_not_nil item_tag.completed_by
      assert_not_nil item_tag.completed_at

      item_tag.reset!

      assert item_tag.idled?
      assert item_tag.unscanned?
      assert_nil item_tag.customer_read_at
      assert_nil item_tag.completed_by_id
      assert_nil item_tag.completed_at
      assert_equal false, item_tag.already_completed
    end
  end

  test "sorted scope orders by queue_number" do
    ActsAsTenant.with_tenant(@account) do
      # Clear existing tags
      @shop.item_tags.destroy_all

      item_tag_c = @shop.item_tags.create!(queue_number: "C01", account: @account)
      item_tag_a = @shop.item_tags.create!(queue_number: "A01", account: @account)
      item_tag_b = @shop.item_tags.create!(queue_number: "B01", account: @account)

      sorted = @shop.item_tags.sorted

      assert_equal [item_tag_a, item_tag_b, item_tag_c], sorted.to_a
    end
  end

  test "sorted_recent_first_order scope orders by completed_at desc" do
    ActsAsTenant.with_tenant(@account) do
      item_tag1 = @shop.item_tags.first
      item_tag2 = @shop.item_tags.second
      item_tag3 = @shop.item_tags.third

      item_tag1.complete_tag!(@shopkeeper)
      sleep 0.01
      item_tag2.complete_tag!(@shopkeeper)
      sleep 0.01
      item_tag3.complete_tag!(@shopkeeper)

      sorted = @shop.item_tags.completed.sorted_recent_first_order

      assert_equal item_tag3, sorted.first
      assert_equal item_tag1, sorted.last
    end
  end
end
