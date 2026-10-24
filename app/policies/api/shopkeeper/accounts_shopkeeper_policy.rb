class Api::Shopkeeper::AccountsShopkeeperPolicy < Api::Shopkeeper::BasePolicy
  include Api::Shopkeeper::Concerns::Authorization

  def index?
    true
  end

  def show?
    true
  end

  def update?
    permitted?(:update_organizations)
  end

  def destroy?
    permitted?(:update_organizations)
  end
end
