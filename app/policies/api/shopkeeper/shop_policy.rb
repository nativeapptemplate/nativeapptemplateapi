class Api::Shopkeeper::ShopPolicy < Api::Shopkeeper::BasePolicy
  include Api::Shopkeeper::Concerns::Authorization

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
end
