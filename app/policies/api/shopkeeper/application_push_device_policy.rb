class Api::Shopkeeper::ApplicationPushDevicePolicy < Api::Shopkeeper::BasePolicy
  def create?
    true
  end

  def destroy?
    record.owner_type == "Shopkeeper" && record.owner_id == accounts_shopkeeper.shopkeeper_id
  end
end
