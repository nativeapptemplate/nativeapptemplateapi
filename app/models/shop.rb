class Shop < ApplicationRecord
  acts_as_tenant :account

  belongs_to :created_by, class_name: "Shopkeeper"

  has_many :item_tags, dependent: :destroy

  validates :name, presence: true
  validate :limit_count, on: :create

  after_create :create_sample_item_tag

  private

  def create_sample_item_tag
    item_tags.create!(
      account: account,
      name: "Sample",
      description: "This is a sample. You can update or delete it.",
      created_by: created_by
    )
  rescue => e
    Rails.logger.warn "Failed to create sample item_tag for Shop #{id}: #{e.message}"
  end

  def limit_count
    ActsAsTenant.without_tenant do
      the_limit_count = ConfigSettings.shop.limit_count
      return if created_by.created_shops.count < the_limit_count

      errors.add :base, :limit_count_shop, limit_count: the_limit_count
    end
  end
end
