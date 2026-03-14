class Api::Shopkeeper::PasswordPolicy < Api::Shopkeeper::BasePolicy
  def update?
    true
  end
end
