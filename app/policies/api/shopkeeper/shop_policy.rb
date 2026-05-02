class Api::Shopkeeper::ShopPolicy < Api::Shopkeeper::BasePolicy
  include Api::Shopkeeper::Concerns::Authorization

  def index?
    admin? || member?
  end

  def show?
    admin? || member?
  end

  def create?
    admin? || member?
  end

  def update?
    admin? || member?
  end

  def destroy?
    admin? || member?
  end
end
