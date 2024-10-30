class AccountsShopkeeperSerializer
  include JSONAPI::Serializer
  cache_options store: Rails.cache, namespace: "jsonapi-serializer", expires_in: 1.hour

  attributes :account_id, :shopkeeper_id

  AccountsShopkeeper::ROLES.each do |role|
    attributes role
  end

  belongs_to :account
  belongs_to :shopkeeper
end
