class Api::Shopkeeper::PermissionPolicy < Api::Shopkeeper::BasePolicy
  def index?
    true
  end
end
