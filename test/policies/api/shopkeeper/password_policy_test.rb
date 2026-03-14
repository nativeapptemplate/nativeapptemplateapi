require "test_helper"

class Api::Shopkeeper::PasswordPolicyTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
    @accounts_shopkeeper = @account.accounts_shopkeepers.first
  end

  test "update? returns true" do
    policy = Api::Shopkeeper::PasswordPolicy.new(@accounts_shopkeeper, :password)
    assert policy.update?
  end
end
