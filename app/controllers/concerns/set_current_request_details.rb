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
    end
  end
end
