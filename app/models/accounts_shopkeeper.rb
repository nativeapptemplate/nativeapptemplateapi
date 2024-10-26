class AccountsShopkeeper < ApplicationRecord
  # Add account roles to this line
  # Do NOT to use any reserved words like `user` or `account`
  ROLES = [:admin, :senior_manager, :junior_manager, :senior_member, :junior_member, :guest]

  include Rolified

  belongs_to :account, touch: true
  belongs_to :shopkeeper

  validates :shopkeeper_id, uniqueness: {scope: :account_id}
  validate :limit_count, on: :create
  validate :owner_must_be_admin, on: :update, if: -> { admin_changed? && account_owner? }

  def account_owner?
    account.owner_id == shopkeeper_id
  end

  def permissions
    role = if admin?
      Role.find_by(tag: "admin")
    elsif senior_manager?
      Role.find_by(tag: "senior_manager")
    elsif junior_manager?
      Role.find_by(tag: "junior_manager")
    elsif senior_member?
      Role.find_by(tag: "senior_member")
    elsif junior_member?
      Role.find_by(tag: "junior_member")
    elsif guest?
      Role.find_by(tag: "guest")
    end

    role.permissions
  end

  private

  def owner_must_be_admin
    return if admin?

    errors.add :admin, :cannot_be_removed
  end

  def limit_count
    the_limit_count = ConfigSettings.accounts_shopkeeper.limit_count
    return if account.accounts_shopkeepers.count < the_limit_count

    errors.add :base, :limit_count_accounts_shopkeeper, limit_count: the_limit_count
  end
end
