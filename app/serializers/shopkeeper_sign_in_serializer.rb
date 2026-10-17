class ShopkeeperSignInSerializer
  include JSONAPI::Serializer

  attributes :email,
    :name,
    :uid,
    :time_zone,
    :feature_access_state,
    :locale,
    :token,
    :client,
    :expiry,
    :account_id

  attribute :personal_account_id do |shopkeeper|
    shopkeeper.personal_account.id
  end

  attribute :account_owner_id do |shopkeeper|
    shopkeeper.personal_account.owner_id
  end

  # The apps' paid-feature checks follow the account owner (see AGENTS.md "Billing")
  attribute :account_owner_feature_access_state do |shopkeeper|
    shopkeeper.personal_account.owner.feature_access_state
  end

  attribute :account_name do |shopkeeper|
    shopkeeper.personal_account.name
  end
end
