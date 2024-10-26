module CurrentShopkeeperHelper
  def current_account
    Current.account
  end

  def current_accounts_shopkeeper
    return unless current_account

    @accounts_shopkeeper ||= current_account.accounts_shopkeepers.includes(:shopkeeper).find_by(shopkeeper: current_shopkeeper)
  end
end
