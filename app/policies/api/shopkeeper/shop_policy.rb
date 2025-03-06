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

  def reset?
    admin? || senior_manager? || junior_manager? || senior_member?
  end
end
