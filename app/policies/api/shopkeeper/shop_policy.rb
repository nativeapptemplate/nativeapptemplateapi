class Api::Shopkeeper::ShopPolicy < Api::Shopkeeper::BasePolicy
  include Api::Shopkeeper::Concerns::Authorization

  def index?
    true
  end

  def create?
    owner?
  end

  def show?
    true
  end

  def update?
    admin?
  end

  def destroy?
    create?
  end
end
