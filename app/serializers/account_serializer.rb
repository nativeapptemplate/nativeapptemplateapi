# No cache for is_admin
class AccountSerializer
  include JSONAPI::Serializer
  attributes :name, :owner_id, :personal

  # Reads the preloaded members instead of querying per account
  attribute :is_admin do |account, params|
    shopkeeper_id = params[:current_shopkeeper]&.id
    account.accounts_shopkeepers.any? { _1.shopkeeper_id == shopkeeper_id && _1.admin? }
  end

  attribute :owner_name do |account|
    account.owner.name
  end

  attribute :accounts_shopkeepers_count do |account|
    account.accounts_shopkeepers.size
  end

  attribute :accounts_invitations_count do |account|
    account.accounts_invitations.size
  end

  # The index passes counts made outside the tenant scope in one query;
  # a single account (show, create, update) is counted directly
  attribute :shops_count do |account, params|
    params[:shops_counts] ? params[:shops_counts].fetch(account.id, 0) : account.shops.size
  end

  belongs_to :owner, serializer: ShopkeeperSerializer
  has_many :accounts_shopkeepers
  has_many :accounts_invitations
end
