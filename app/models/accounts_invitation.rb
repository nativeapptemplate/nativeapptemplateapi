class AccountsInvitation < ApplicationRecord
  ROLES = AccountsShopkeeper::ROLES
  EXPIRES_IN = ConfigSettings.accounts_invitation.expires_in_hours.hours

  include Rolified

  belongs_to :account
  belongs_to :invited_by, class_name: "Shopkeeper", optional: true

  validates :name, :email, presence: true
  validates :email, uniqueness: {scope: :account_id, message: :invited}

  before_create :set_token

  scope :active, -> { where(created_at: EXPIRES_IN.ago..) }
  scope :expired, -> { where(created_at: ...EXPIRES_IN.ago) }

  def expired?
    created_at < EXPIRES_IN.ago
  end

  def save_and_send_invite
    save && send_invite
  end

  def send_invite
    Shopkeeper::NotificationMailer.with(accounts_invitation: self).invited.deliver_later
  end

  def resend_invite
    touch(:created_at)
    send_invite
  end

  def accept!(shopkeeper)
    accounts_shopkeeper = account.accounts_shopkeepers.new(shopkeeper: shopkeeper, roles: roles)
    if accounts_shopkeeper.valid?
      ApplicationRecord.transaction do
        accounts_shopkeeper.save!
        destroy!
      end

      accounts_shopkeeper
    else
      errors.add(:base, accounts_shopkeeper.errors.full_messages.first)
      nil
    end
  end

  def reject!
    destroy
  end

  def to_param
    token
  end

  private

  def set_token
    the_token = nil

    loop do
      the_token = random_token
      break unless AccountsInvitation.exists?(token: the_token)
    end

    self.token = the_token
  end

  def random_token
    random_seed = "0123456789"
    Array.new(6) { random_seed.chars.sample }.join
  end
end
