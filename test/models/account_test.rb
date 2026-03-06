require "test_helper"

class AccountTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
  end

  test "should be valid with valid attributes" do
    account = Account.new(name: "Test Account", owner: @shopkeeper)
    assert account.valid?
  end

  test "should require name" do
    account = Account.new(owner: @shopkeeper)
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "should belong to owner" do
    account = Account.new(name: "Test Account", owner: @shopkeeper)
    assert_equal @shopkeeper, account.owner
  end

  test "should create default shop after creation" do
    account = Account.create!(name: "Test Account", owner: @shopkeeper)
    assert_equal 1, account.shops.count
    assert_equal ConfigSettings.shop.default_name, account.shops.first.name
  end

  test "personal? scope returns personal accounts" do
    personal_account = Account.create!(name: "Personal", owner: @shopkeeper, personal: true)
    team_account = Account.create!(name: "Team", owner: @shopkeeper, personal: false)

    assert_includes Account.personal, personal_account
    assert_not_includes Account.personal, team_account
  end

  test "team scope returns team accounts" do
    personal_account = Account.create!(name: "Personal", owner: @shopkeeper, personal: true)
    team_account = Account.create!(name: "Team", owner: @shopkeeper, personal: false)

    assert_includes Account.team, team_account
    assert_not_includes Account.team, personal_account
  end

  test "personal_account_for? returns true for owner's personal account" do
    account = Account.create!(name: "Personal", owner: @shopkeeper, personal: true)
    assert account.personal_account_for?(@shopkeeper)
  end

  test "personal_account_for? returns false for team account" do
    account = Account.create!(name: "Team", owner: @shopkeeper, personal: false)
    assert_not account.personal_account_for?(@shopkeeper)
  end

  test "owner? returns true for account owner" do
    account = Account.create!(name: "Test Account", owner: @shopkeeper)
    assert account.owner?(@shopkeeper)
  end

  test "owner? returns false for non-owner" do
    other_shopkeeper = shopkeepers(:two)
    account = Account.create!(name: "Test Account", owner: @shopkeeper)
    assert_not account.owner?(other_shopkeeper)
  end

  test "admin? returns true when shopkeeper is admin" do
    account = Account.create!(name: "Test Account", owner: @shopkeeper)
    AccountsShopkeeper.create!(
      account: account,
      shopkeeper: @shopkeeper,
      admin: true
    )

    assert account.admin?(@shopkeeper)
  end

  test "admin? returns false when shopkeeper is not admin" do
    other_shopkeeper = shopkeepers(:two)
    account = Account.create!(name: "Test Account", owner: @shopkeeper)
    AccountsShopkeeper.create!(
      account: account,
      shopkeeper: other_shopkeeper,
      admin: false,
      junior_member: true
    )

    assert_not account.admin?(other_shopkeeper)
  end

  test "admin? returns false when shopkeeper is not a member" do
    other_shopkeeper = shopkeepers(:two)
    account = Account.create!(name: "Test Account", owner: @shopkeeper)

    assert_not account.admin?(other_shopkeeper)
  end

  test "should destroy associated accounts_invitations" do
    account = Account.create!(name: "Test Account", owner: @shopkeeper)
    AccountsInvitation.create!(
      account: account,
      name: "Test User",
      email: "test@example.com",
      junior_member: true
    )

    assert_difference "AccountsInvitation.count", -1 do
      account.destroy
    end
  end

  test "should destroy associated accounts_shopkeepers" do
    account = Account.create!(name: "Test Account", owner: @shopkeeper)
    AccountsShopkeeper.create!(
      account: account,
      shopkeeper: @shopkeeper,
      admin: true
    )

    assert_difference "AccountsShopkeeper.count", -1 do
      account.destroy
    end
  end

  test "should destroy associated shops" do
    account = Account.create!(name: "Test Account", owner: @shopkeeper)

    assert_difference "Shop.count", -1 do
      account.destroy
    end
  end

  test "sorted scope orders personal accounts first, then by name" do
    account_b_team = Account.create!(name: "B Team", owner: @shopkeeper, personal: false)
    account_a_personal = Account.create!(name: "A Personal", owner: @shopkeeper, personal: true)
    account_c_team = Account.create!(name: "C Team", owner: @shopkeeper, personal: false)

    sorted_accounts = Account.sorted.where(id: [account_b_team.id, account_a_personal.id, account_c_team.id])

    assert_equal account_a_personal.id, sorted_accounts.first.id
    assert_equal [account_b_team.id, account_c_team.id], sorted_accounts.last(2).map(&:id)
  end
end
