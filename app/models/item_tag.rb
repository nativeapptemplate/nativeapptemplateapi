class ItemTag < ApplicationRecord
  include AASM

  acts_as_tenant :account

  belongs_to :shop
  belongs_to :created_by, class_name: "Shopkeeper", optional: true
  belongs_to :completed_by, class_name: "Shopkeeper", optional: true

  enum :state, {idled: 1, completed: 2}

  validates :name, presence: true
  validate :limit_count, on: :create

  before_create :set_default_position

  aasm(:state, column: "state") do
    state :idled, initial: true
    state :completed

    event :idle do
      transitions from: [:idled, :completed], to: :idled
    end

    event :complete do
      transitions from: [:idled], to: :completed
    end
  end

  private

  def set_default_position
    return if position.present?

    self.position = (shop.item_tags.maximum(:position) || 0) + 1
  end

  def limit_count
    the_limit_count = ConfigSettings.item_tag.limit_count
    return if shop.item_tags.count < the_limit_count

    errors.add :base, :limit_count_item_tag, limit_count: the_limit_count
  end
end
