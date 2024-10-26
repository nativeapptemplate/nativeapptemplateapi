class Shop < ApplicationRecord
  acts_as_tenant :account

  belongs_to :created_by, class_name: "Shopkeeper"

  validates :name, presence: true
  validate :limit_count, on: :create

  private

  def limit_count
    ActsAsTenant.without_tenant do
      the_limit_count = ConfigSettings.shop.limit_count
      return if created_by.created_shops.count < the_limit_count

      errors.add :base, :limit_count_shop, limit_count: the_limit_count
    end
  end
end
