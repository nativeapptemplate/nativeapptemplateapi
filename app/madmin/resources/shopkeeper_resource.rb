class ShopkeeperResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :provider
  attribute :uid
  attribute :encrypted_password
  attribute :reset_password_token
  attribute :reset_password_sent_at
  attribute :allow_password_change
  attribute :remember_created_at
  attribute :confirmation_token
  attribute :confirmed_at
  attribute :confirmation_sent_at
  attribute :unconfirmed_email
  attribute :name
  attribute :nickname
  attribute :image
  attribute :email
  attribute :tokens, form: false
  attribute :sign_in_count, form: false
  attribute :current_sign_in_at
  attribute :last_sign_in_at
  attribute :current_sign_in_ip
  attribute :last_sign_in_ip
  attribute :locale
  attribute :time_zone
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :current_platform
  attribute :confirmed_privacy_version
  attribute :confirmed_terms_version
  attribute :token, index: false
  attribute :client, index: false
  attribute :expiry, index: false
  attribute :account_id, index: false

  # Associations
  attribute :accounts_invitations
  attribute :accounts_shopkeepers
  attribute :accounts
  attribute :owned_accounts
  attribute :personal_account
  attribute :shops
  attribute :created_shops

  # Add scopes to easily filter records
  # scope :published

  # Add actions to the resource's show page
  # member_action do |record|
  #   link_to "Do Something", some_path
  # end

  # Customize the display name of records in the admin area.
  # def self.display_name(record) = record.name

  # Customize the default sort column and direction.
  # def self.default_sort_column = "created_at"
  #
  # def self.default_sort_direction = "desc"
end
