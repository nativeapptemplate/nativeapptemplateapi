class Account < ApplicationRecord
  belongs_to :owner, class_name: "Shopkeeper"
  has_many :accounts_invitations, dependent: :destroy
  has_many :accounts_shopkeepers, dependent: :destroy
  has_many :shopkeepers, through: :accounts_shopkeepers
  has_many :shops, dependent: :destroy

  scope :personal, -> { where(personal: true) }
  scope :team, -> { where(personal: false) }
  scope :sorted, -> { order(personal: :desc, name: :asc) }

  validates :name, presence: true
  validate :limit_count, on: :create

  after_create :create_default_shop!

  def admin?(shopkeeper)
    accounts_shopkeeper = AccountsShopkeeper.find_by(account: self, shopkeeper: shopkeeper)
    return false if accounts_shopkeeper.blank?

    accounts_shopkeeper.admin?
  end

  private

  def create_default_shop!
    return if reached_limit_shop_count?

    ActsAsTenant.without_tenant do
      shop = shops.build
      shop.name = ConfigSettings.shop.default_name
      shop.time_zone = owner.time_zone
      shop.created_by = owner
      shop.description = I18n.t("default_shop_description")
      shop.save!
    end
  end

  def reached_limit_shop_count?
    ActsAsTenant.without_tenant do
      ConfigSettings.shop.limit_count <= owner.created_shops.count
    end
  end

  def limit_count
    the_limit_count = ConfigSettings.account.limit_count
    return if owner.owned_accounts.count < the_limit_count

    errors.add :base, :limit_count_account, limit_count: the_limit_count
  end
end
