class Api::Shopkeeper::DevicePolicy < Api::Shopkeeper::BasePolicy
  def create?
    true
  end

  def destroy?
    record.shopkeeper_id == accounts_shopkeeper.shopkeeper_id
  end
end
