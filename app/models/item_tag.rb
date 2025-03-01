class ItemTag < ApplicationRecord
  include AASM

  acts_as_tenant :account

  belongs_to :shop
  belongs_to :created_by, class_name: "Shopkeeper", optional: true
  belongs_to :completed_by, class_name: "Shopkeeper", optional: true

  enum state: {idled: 1, completed: 2}
  enum scan_state: {unscanned: 1, scanned: 2}

  scope :sorted, -> { order(queue_number: :asc) }
  scope :sorted_recent_first_order, -> { order(completed_at: :desc) }

  validates :queue_number, presence: true
  validates :queue_number, uniqueness: {scope: :shop_id, message: :uniqueness_error}
  validates :queue_number,
    format: {
      with: /\A[A-Za-z0-9]{2,5}\z/, message: :format_error
    }

  validate :limit_count, on: :create

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

  aasm(:scan_state, column: "scan_state") do
    state :unscanned, initial: true
    state :scanned

    event :scan do
      transitions from: [:unscanned], to: :scanned
    end

    event :unscan do
      transitions from: [:unscanned, :scanned], to: :unscanned
    end
  end

  after_update_commit :update_item_tags_if_needed
  after_destroy_commit :update_item_tags

  def scan_tag!
    return unless may_scan?

    self.customer_read_at = Time.current
    scan!
  end

  def complete_tag!(shopkeeper)
    return unless may_complete?

    self.completed_by = shopkeeper
    self.already_completed = false
    self.completed_at = Time.current
    complete!
  end

  def reset!
    self.customer_read_at = nil
    self.completed_by_id = nil
    self.completed_at = nil
    self.already_completed = false
    unscan
    idle

    save!
  end

  private

  def limit_count
    the_limit_count = ConfigSettings.item_tag.limit_count
    return if shop.item_tags.count < the_limit_count

    errors.add :base, :limit_count_item_tag, limit_count: the_limit_count
  end

  def update_item_tags_if_needed
    return unless state_previously_changed? || queue_number_previously_changed?

    update_item_tags
  end

  def update_item_tags
    broadcast_append_to [shop, :tb_stream_update_item_tags],
      target: "tb_display_container",
      partial: "display/shops/update_item_tags"
  end
end
