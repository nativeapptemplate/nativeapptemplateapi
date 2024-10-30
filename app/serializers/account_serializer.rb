# No cache for is_admin
class AccountSerializer
  include JSONAPI::Serializer
  attributes :name, :owner_id, :personal

  attribute :is_admin do |account, params|
    account.admin?(params[:current_shopkeeper])
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

  attribute :shops_count do |account|
    account.shops.size
  end

  belongs_to :owner, serializer: ShopkeeperSerializer
  has_many :accounts_shopkeepers
  has_many :accounts_invitations
end
