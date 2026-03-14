class Api::Shopkeeper::MePolicy < Api::Shopkeeper::BasePolicy
  def update_confirmed_privacy_version?
    true
  end

  def update_confirmed_terms_version?
    true
  end
end
