class Api::Shopkeeper::AccountsInvitationPolicy < Api::Shopkeeper::BasePolicy
  include Api::Shopkeeper::Concerns::Authorization

  def index?
    true
  end

  def show?
    true
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  def resend?
    admin?
  end

  # Token-based actions (any authenticated shopkeeper with the token)
  def show_by_token?
    true
  end

  def accept?
    true
  end

  def reject?
    true
  end
end
