class Account < ApplicationRecord
  belongs_to :owner, class_name: "Shopkeeper"
  has_many :accounts_invitations, dependent: :destroy
  has_many :accounts_shopkeepers, dependent: :destroy
  has_many :shopkeepers, through: :accounts_shopkeepers
  has_many :shops, dependent: :destroy

  scope :sorted, -> { order(personal: :desc, name: :asc) }

  validates :name, presence: true
  validate :limit_count, on: :create

  after_create :create_default_shop!

  private

  # In the owner's language, not the request's: at sign-up the request's
  # language comes from Accept-Language, which can differ from the one stored.
  # Under this account as the tenant, so records the shop creates in turn
  # (acts_as_tenant :account) get its account_id without passing it
  def create_default_shop!
    return if reached_limit_shop_count?

    I18n.with_locale(owner.locale) do
      ActsAsTenant.with_tenant(self) do
        shop = shops.build
        shop.name = I18n.t("default_shop_name")
        shop.time_zone = owner.time_zone
        shop.created_by = owner
        shop.description = I18n.t("default_shop_description")
        shop.save!
      end
    end
  end

  def reached_limit_shop_count?
    ActsAsTenant.without_tenant do
      ConfigSettings.shop.limit_count <= owner.created_shops.count
    end
  end

  def limit_count
    limit = ConfigSettings.account.limit_count
    return if owner.owned_accounts.count < limit

    errors.add :base, :limit_count_account, limit_count: limit
  end
end
