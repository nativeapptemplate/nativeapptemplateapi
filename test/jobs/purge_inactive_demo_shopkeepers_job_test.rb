require "test_helper"

class PurgeInactiveDemoShopkeepersJobTest < ActiveJob::TestCase
  def build_shopkeeper(email, created_at:, current_sign_in_at: nil)
    shopkeeper = Shopkeeper.create!(name: "Demo", email: email, password: "password", current_platform: "ios")
    shopkeeper.update_columns(created_at: created_at, current_sign_in_at: current_sign_in_at)
    shopkeeper
  end

  def with_env(value)
    original = ENV["DEMO_PURGE_INACTIVE_DAYS"]
    ENV["DEMO_PURGE_INACTIVE_DAYS"] = value
    yield
  ensure
    ENV["DEMO_PURGE_INACTIVE_DAYS"] = original
  end

  # Generated apps inherit this job and the recurring task. Without the
  # variable it must never delete anyone.
  test "does nothing when DEMO_PURGE_INACTIVE_DAYS is unset" do
    build_shopkeeper("old@example.com", created_at: 1.year.ago, current_sign_in_at: 1.year.ago)

    with_env(nil) do
      assert_no_difference("Shopkeeper.count") { PurgeInactiveDemoShopkeepersJob.perform_now }
    end
  end

  test "deletes shopkeepers whose last sign-in, or sign-up if they never signed in, is older than the limit" do
    signed_in_long_ago = build_shopkeeper("a@example.com", created_at: 60.days.ago, current_sign_in_at: 31.days.ago)
    never_signed_in = build_shopkeeper("b@example.com", created_at: 31.days.ago)
    signed_in_recently = build_shopkeeper("c@example.com", created_at: 60.days.ago, current_sign_in_at: 29.days.ago)
    signed_up_recently = build_shopkeeper("d@example.com", created_at: 29.days.ago)
    owned_account_ids = signed_in_long_ago.owned_accounts.ids

    with_env("30") { PurgeInactiveDemoShopkeepersJob.perform_now }

    assert_not Shopkeeper.exists?(signed_in_long_ago.id)
    assert_not Shopkeeper.exists?(never_signed_in.id)
    assert Shopkeeper.exists?(signed_in_recently.id)
    assert Shopkeeper.exists?(signed_up_recently.id)
    assert_not_empty owned_account_ids
    assert_not Account.where(id: owned_account_ids).exists?
  end

  test "rejects a value that is not a positive whole number of days" do
    build_shopkeeper("old@example.com", created_at: 1.year.ago)

    %w[abc 0 -5].each do |value|
      with_env(value) do
        assert_raises(ArgumentError) { PurgeInactiveDemoShopkeepersJob.perform_now }
      end
    end
  end
end
