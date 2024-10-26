module Api::Shopkeeper::Concerns::Authorization
  private

  AccountsShopkeeper::ROLES.each do |role|
    define_method(:"#{role}?") do
      accounts_shopkeeper.active_roles.include?(role)
    end
  end

  def owner?
    accounts_shopkeeper.account_owner?
  end
end
