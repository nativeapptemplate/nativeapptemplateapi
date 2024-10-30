module Shopkeeper::Accounts
  extend ActiveSupport::Concern

  included do
    has_many :accounts_invitations, dependent: :nullify, foreign_key: :invited_by_id
    has_many :accounts_shopkeepers, dependent: :destroy
    has_many :accounts, through: :accounts_shopkeepers
    has_many :owned_accounts, class_name: "Account", foreign_key: :owner_id, inverse_of: :owner, dependent: :destroy
    has_one :personal_account, -> { where(personal: true) }, class_name: "Account", foreign_key: :owner_id, inverse_of: :owner, dependent: :destroy

    # Regular shopkeepers should get their account created immediately
    after_create :create_default_account
    after_update :sync_personal_account_name
  end

  def create_default_account
    # Invited shopkeepers don't have a name immediately, so we will run this method twice for them
    # once on create where no name is present and again on accepting the invitation
    return if name.blank?
    return accounts.first if accounts.any?

    account = accounts.new(owner: self, name: name, personal: true)
    account.accounts_shopkeepers.new(shopkeeper: self, admin: true)
    account.save!
    account
  end

  def sync_personal_account_name
    if name_previously_changed?
      # Accepting an invitation calls this when the user's name is updated
      if personal_account.nil?
        create_default_account
        reload_personal_account
      end

      # Sync the personal account name with the user's name
      personal_account.update(name: name)
    end
  end
end
