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
      item_tag = @shop.item_tags.new(name: "Buy milk", account: @account)
      assert item_tag.valid?
    end
  end

  test "should require name" do
    ActsAsTenant.with_tenant(@account) do
      item_tag = @shop.item_tags.new(account: @account)
      assert_not item_tag.valid?
      assert_includes item_tag.errors[:name], "can't be blank"
    end
  end

  test "should allow same name in different shops" do
    ActsAsTenant.with_tenant(@account) do
      shop2 = @account.shops.create!(name: "Shop 2", created_by: @shopkeeper)

      @shop.item_tags.create!(name: "Buy milk", account: @account)
      item_tag2 = shop2.item_tags.create!(name: "Buy milk", account: @account)

      assert item_tag2.valid?
    end
  end

  test "should allow duplicate names within the same shop" do
    ActsAsTenant.with_tenant(@account) do
      @shop.item_tags.create!(name: "Buy milk", account: @account)
      duplicate = @shop.item_tags.new(name: "Buy milk", account: @account)

      assert duplicate.valid?
    end
  end

  test "should round-trip description and position" do
    ActsAsTenant.with_tenant(@account) do
      item_tag = @shop.item_tags.create!(
        name: "Buy bread",
        description: "Whole grain only",
        position: 7,
        account: @account
      )

      assert_equal "Whole grain only", item_tag.reload.description
      assert_equal 7, item_tag.position
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
      item_tag = @shop.item_tags.create!(name: "Buy eggs", account: @account)
      assert item_tag.idled?
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
end
