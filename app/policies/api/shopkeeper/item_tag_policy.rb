class Api::Shopkeeper::ItemTagPolicy < Api::Shopkeeper::BasePolicy
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
    create?
  end

  def destroy?
    create?
  end

  def complete?
    create?
  end

  def idle?
    create?
  end
end
