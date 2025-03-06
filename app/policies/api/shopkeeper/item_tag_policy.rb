class Api::Shopkeeper::ItemTagPolicy < Api::Shopkeeper::BasePolicy
  include Api::Shopkeeper::Concerns::Authorization

  def index?
    true
  end

  def create?
    admin? || senior_manager?
  end

  def show?
    true
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  def complete?
    admin? || senior_manager? || junior_manager? || senior_member? || junior_member?
  end

  def reset?
    complete?
  end
end
