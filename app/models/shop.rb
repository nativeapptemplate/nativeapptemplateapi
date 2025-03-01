class Shop < ApplicationRecord
  acts_as_tenant :account

  belongs_to :created_by, class_name: "Shopkeeper"

  has_many :item_tags, dependent: :destroy

  validates :name, presence: true
  validate :limit_count, on: :create

  after_create :create_default_item_tags!

  def latest_completed_item_tag
    item_tags.completed.sorted_recent_first_order.first
  end

  def create_default_item_tags!
    return if item_tags.present?

    ConfigSettings.item_tag.default_count.times do |i|
      queue_number_length = ConfigSettings.item_tag.default_queue_number_length
      number = (i + 1).to_s.rjust(queue_number_length - 1, "0")
      queue_number = "A#{number}"

      item_tag = item_tags.build
      item_tag.account = account
      item_tag.queue_number = queue_number
      item_tag.save!
    end
  end

  def reset!
    item_tags.each do |item_tag|
      item_tag.reset!
    end

    full_reload_entire_page
  end

  private

  def limit_count
    ActsAsTenant.without_tenant do
      the_limit_count = ConfigSettings.shop.limit_count
      return if created_by.created_shops.count < the_limit_count

      errors.add :base, :limit_count_shop, limit_count: the_limit_count
    end
  end

  def full_reload_entire_page
    broadcast_append_to [self, :tb_stream_full_reload_entire_page],
      target: "tb_display_container",
      partial: "display/shops/full_reload_entire_page"
  end
end
