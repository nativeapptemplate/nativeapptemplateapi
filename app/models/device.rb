class Device < ApplicationRecord
  belongs_to :shopkeeper

  enum :platform, {ios: "ios", android: "android"}

  validates :token, presence: true, uniqueness: {scope: :platform}
  validates :platform, presence: true

  scope :active, -> { where("last_active_at > ?", 90.days.ago) }

  before_validation :touch_last_active_at, on: :create

  private

  def touch_last_active_at
    self.last_active_at ||= Time.current
  end
end
