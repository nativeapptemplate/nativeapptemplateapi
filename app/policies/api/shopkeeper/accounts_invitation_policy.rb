class Api::Shopkeeper::AccountsInvitationPolicy < Api::Shopkeeper::BasePolicy
  include Api::Shopkeeper::Concerns::Authorization

  def index?
    true
  end

  def show?
    true
  end

  def create?
    permitted?(:invitation)
  end

  def update?
    permitted?(:invitation)
  end

  def destroy?
    permitted?(:invitation)
  end

  def resend?
    permitted?(:invitation)
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
