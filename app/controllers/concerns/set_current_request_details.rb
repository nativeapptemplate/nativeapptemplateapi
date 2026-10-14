module SetCurrentRequestDetails
  extend ActiveSupport::Concern

  included do
    set_current_tenant_through_filter

    before_action do
      Current.request_id = request.uuid
      Current.user_agent = request.user_agent
      Current.ip_address = request.ip
      Current.shopkeeper = current_shopkeeper

      # Fallback accounts
      if shopkeeper_signed_in?
        Current.account ||= current_shopkeeper.accounts.order(created_at: :asc).first
        Current.account ||= current_shopkeeper.create_default_account
      end

      set_current_tenant(Current.account)
      set_sentry_context
    end
  end

  private

  # IDs only: no email or name goes to Sentry (config/initializers/sentry.rb).
  # Both calls are no-ops when Sentry is not initialised.
  def set_sentry_context
    Sentry.set_user(id: current_shopkeeper.id) if current_shopkeeper
    Sentry.set_tags(account_id: Current.account.id) if Current.account
  end
end
