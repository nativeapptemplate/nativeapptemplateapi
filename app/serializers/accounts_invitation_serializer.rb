class AccountsInvitationSerializer
  include JSONAPI::Serializer
  cache_options store: Rails.cache, namespace: "jsonapi-serializer", expires_in: 1.hour

  attributes :account_id, :invited_by_id, :name, :token, :email

  AccountsShopkeeper::ROLES.each do |role|
    attributes role
  end

  belongs_to :account
  belongs_to :invited_by, serializer: ShopkeeperSerializer
end
