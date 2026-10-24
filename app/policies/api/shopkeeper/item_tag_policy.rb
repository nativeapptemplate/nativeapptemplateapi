class Api::Shopkeeper::ItemTagPolicy < Api::Shopkeeper::BasePolicy
  include Api::Shopkeeper::Concerns::Authorization

  # Item tags belong to a shop, so the shop permissions cover them (as in the apps)
  def index?
    permitted?(:read_data)
  end

  def show?
    permitted?(:read_data)
  end

  def create?
    permitted?(:create_shops)
  end

  def update?
    permitted?(:update_shops)
  end

  def destroy?
    permitted?(:delete_shops)
  end

  def complete?
    update?
  end

  def idle?
    update?
  end
end
