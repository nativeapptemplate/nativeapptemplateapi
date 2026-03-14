require "test_helper"

class Api::Shopkeeper::MePolicyTest < ActiveSupport::TestCase
  def setup
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
    @accounts_shopkeeper = @account.accounts_shopkeepers.first
  end

  test "update_confirmed_privacy_version? returns true" do
    policy = Api::Shopkeeper::MePolicy.new(@accounts_shopkeeper, :me)
    assert policy.update_confirmed_privacy_version?
  end

  test "update_confirmed_terms_version? returns true" do
    policy = Api::Shopkeeper::MePolicy.new(@accounts_shopkeeper, :me)
    assert policy.update_confirmed_terms_version?
  end
end
