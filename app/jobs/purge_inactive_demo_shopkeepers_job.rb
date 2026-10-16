# The public demo lets anyone sign up, so it deletes shopkeepers who have not
# signed in for DEMO_PURGE_INACTIVE_DAYS days, with their owned accounts, shops
# and item tags. The variable is set only in config/deploy.demo.yml; unset (as in
# every generated app) this job does nothing.
#
# devise_token_auth tokens expire 30 days after sign-in (token_lifespan), so with
# 30 days or more nobody still using the app is deleted.
class PurgeInactiveDemoShopkeepersJob < ApplicationJob
  queue_as :default

  def perform
    value = ENV["DEMO_PURGE_INACTIVE_DAYS"]
    return if value.blank?

    days = Integer(value, 10)
    raise ArgumentError, "DEMO_PURGE_INACTIVE_DAYS must be a positive number of days, got #{value.inspect}" unless days.positive?

    Shopkeeper.where("COALESCE(current_sign_in_at, created_at) < ?", days.days.ago).find_each(&:destroy!)
  end
end
