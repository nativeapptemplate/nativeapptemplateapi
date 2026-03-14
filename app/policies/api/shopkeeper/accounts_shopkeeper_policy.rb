class Api::Shopkeeper::AccountsShopkeeperPolicy < Api::Shopkeeper::BasePolicy
  include Api::Shopkeeper::Concerns::Authorization

  def index?
    true
  end

  def show?
    true
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end
end
