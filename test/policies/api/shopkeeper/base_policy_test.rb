require "test_helper"

class Api::Shopkeeper::BasePolicyTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
    @accounts_shopkeeper = @account.accounts_shopkeepers.first
    @record = @account
  end

  test "initialize raises error when accounts_shopkeeper is nil" do
    assert_raises Pundit::NotAuthorizedError do
      Api::Shopkeeper::BasePolicy.new(nil, @record)
    end
  end

  test "initialize succeeds when accounts_shopkeeper is present" do
    policy = Api::Shopkeeper::BasePolicy.new(@accounts_shopkeeper, @record)
    assert_equal @accounts_shopkeeper, policy.accounts_shopkeeper
    assert_equal @record, policy.record
  end

  test "index? returns false by default" do
    policy = Api::Shopkeeper::BasePolicy.new(@accounts_shopkeeper, @record)
    assert_not policy.index?
  end

  test "show? returns false by default" do
    policy = Api::Shopkeeper::BasePolicy.new(@accounts_shopkeeper, @record)
    assert_not policy.show?
  end

  test "create? returns false by default" do
    policy = Api::Shopkeeper::BasePolicy.new(@accounts_shopkeeper, @record)
    assert_not policy.create?
  end

  test "new? delegates to create?" do
    policy = Api::Shopkeeper::BasePolicy.new(@accounts_shopkeeper, @record)
    assert_equal policy.create?, policy.new?
  end

  test "update? returns false by default" do
    policy = Api::Shopkeeper::BasePolicy.new(@accounts_shopkeeper, @record)
    assert_not policy.update?
  end

  test "edit? delegates to update?" do
    policy = Api::Shopkeeper::BasePolicy.new(@accounts_shopkeeper, @record)
    assert_equal policy.update?, policy.edit?
  end

  test "destroy? returns false by default" do
    policy = Api::Shopkeeper::BasePolicy.new(@accounts_shopkeeper, @record)
    assert_not policy.destroy?
  end

  test "Scope raises error when accounts_shopkeeper is nil" do
    assert_raises Pundit::NotAuthorizedError do
      Api::Shopkeeper::BasePolicy::Scope.new(nil, Account)
    end
  end

  test "Scope initialize succeeds when accounts_shopkeeper is present" do
    scope = Api::Shopkeeper::BasePolicy::Scope.new(@accounts_shopkeeper, Account)
    assert_not_nil scope
  end

  test "Scope resolve returns all records by default" do
    scope = Api::Shopkeeper::BasePolicy::Scope.new(@accounts_shopkeeper, Account)
    assert_equal Account.all, scope.resolve
  end
end
