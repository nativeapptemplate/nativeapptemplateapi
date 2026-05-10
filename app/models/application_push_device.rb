class ApplicationPushDevice < ActionPushNative::Device
  # Inherits `enum :platform, {apple: "apple", google: "google"}, validate: true`
  # from ActionPushNative::Device (apple = APNs, google = FCM).

  validates :token, presence: true, uniqueness: {scope: :platform}

  scope :active, -> { where("last_active_at > ?", 90.days.ago) }

  before_validation :touch_last_active_at, on: :create

  # Customize TokenError handling (default: destroy!)
  # rescue_from (ActionPushNative::TokenError) { Rails.logger.error("Device #{id} token is invalid") }

  private

  def touch_last_active_at
    self.last_active_at ||= Time.current
  end
end
