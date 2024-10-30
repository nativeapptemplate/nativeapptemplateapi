class Shopkeeper < ApplicationRecord
  extend Devise::Models
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable, :confirmable
  include DeviseTokenAuth::Concerns::User
  include Shopkeeper::Accounts

  has_many :shops, through: :accounts
  has_many :created_shops, class_name: "Shop", foreign_key: :created_by_id, inverse_of: :created_by

  attribute :token, :string
  attribute :client, :string
  attribute :expiry, :string

  attribute :account_id, :string

  validates :name, presence: true

  validates :current_platform,
    presence: true,
    inclusion: {in: %w[ios android]}

  scope :android, -> { where(current_platform: "android") }
  scope :ios, -> { where(current_platform: "ios") }

  # override devise method to include additional info as opts hash
  def send_confirmation_instructions(opts = {})
    generate_confirmation_token! unless @raw_confirmation_token

    # fall back to "default" config name
    opts[:client_config] ||= "default"
    opts[:to] = unconfirmed_email if pending_reconfirmation?
    opts[:redirect_url] ||= DeviseTokenAuth.default_confirm_success_url

    # send_devise_notification(:confirmation_instructions, @raw_confirmation_token, opts)
    Shopkeeper::NotificationMailer.with(resource: self, token: @raw_confirmation_token, opts: opts).confirmation_instructions.deliver_later
  end

  # override devise method to include additional info as opts hash
  def send_reset_password_instructions(opts = {})
    token = set_reset_password_token

    # fall back to "default" config name
    opts[:client_config] ||= "default"

    # send_devise_notification(:reset_password_instructions, token, opts)
    Shopkeeper::NotificationMailer.with(resource: self, token: token, opts: opts).reset_password_instructions.deliver_later

    token
  end
end
