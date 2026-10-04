require "test_helper"

class IndexSerializationTest < ActionDispatch::IntegrationTest
  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @headers = @shopkeeper.create_new_auth_token
  end

  # The request runs with the shopkeeper's first account as the tenant, and
  # Shop is acts_as_tenant, so counting through account.shops saw only that
  # account's shops.
  test "accounts index counts shops for every account, not just the current one" do
    team = add_team_account("Team A")

    get api_v1_shopkeeper_accounts_url, headers: @headers

    assert_response :success
    counts = response.parsed_body["data"].to_h { [_1["id"], _1["attributes"]["shops_count"]] }
    # Oracle: count straight from the table, outside any tenant scope
    expected = ActsAsTenant.without_tenant { Shop.where(account_id: counts.keys).group(:account_id).count }
    assert_equal 1, expected[team.id], "Account#after_create makes one default shop"
    assert_equal expected, counts
  end

  test "accounts index runs the same number of queries for one account or several" do
    one = index_queries { get api_v1_shopkeeper_accounts_url, headers: @headers }
    3.times { |i| add_team_account("Team #{i}") }
    many = index_queries { get api_v1_shopkeeper_accounts_url, headers: @headers }

    assert_equal 4, response.parsed_body["data"].size
    assert_equal one, many
  end

  test "accounts index reports is_admin per account" do
    team = add_team_account("Member only", admin: false)

    get api_v1_shopkeeper_accounts_url, headers: @headers

    admin = response.parsed_body["data"].to_h { [_1["id"], _1["attributes"]["is_admin"]] }
    assert_equal false, admin[team.id]
    assert_equal true, admin[@shopkeeper.accounts.find_by(personal: true).id]
  end

  test "shops index runs the same number of queries for one shop or several" do
    one = index_queries { get api_v1_shopkeeper_shops_url, headers: @headers }
    account = @shopkeeper.accounts.first
    ActsAsTenant.with_tenant(account) do
      2.times { |i| Shop.create!(account: account, name: "Shop #{i}", created_by: @shopkeeper) }
    end
    many = index_queries { get api_v1_shopkeeper_shops_url, headers: @headers }

    assert_equal 3, response.parsed_body["data"].size
    assert_equal one, many
  end

  test "shops index counts item tags and completed item tags" do
    shop = @shopkeeper.created_shops.first
    ActsAsTenant.with_tenant(shop.account) { shop.item_tags.first.complete! }

    get api_v1_shopkeeper_shops_url, headers: @headers

    attrs = response.parsed_body["data"].find { _1["id"] == shop.id }["attributes"]
    # Oracle: count straight from the table
    tags = ItemTag.unscoped.where(shop_id: shop.id)
    assert_equal tags.count, attrs["item_tags_count"]
    assert_equal tags.where(state: :completed).count, attrs["completed_item_tags_count"]
    assert_equal 1, attrs["completed_item_tags_count"]
  end

  private

  def add_team_account(name, admin: true)
    account = Account.create!(name: name, owner: @shopkeeper, personal: false)
    AccountsShopkeeper.create!(account: account, shopkeeper: @shopkeeper, admin: admin, member: !admin)
    account
  end

  def index_queries(&)
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name].in?(%w[SCHEMA TRANSACTION]) || payload[:cached] }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    count
  end
end
