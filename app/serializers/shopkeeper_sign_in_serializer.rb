class ShopkeeperSignInSerializer
  include JSONAPI::Serializer

  attributes :email,
    :name,
    :uid,
    :time_zone,
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

  attribute :account_name do |shopkeeper|
    shopkeeper.personal_account.name
  end
end
