class Api::Shopkeeper::AccountPolicy < Api::Shopkeeper::BasePolicy
  include Api::Shopkeeper::Concerns::Authorization

  def index?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def update?
    admin?
  end

  def destroy?
    owner?
  end
end
