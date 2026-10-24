module Api::Shopkeeper::Concerns::Authorization
  private

  def owner?
    accounts_shopkeeper.account_owner?
  end

  # What a role may do is the roles_permissions table (db/fixtures/*/03_roles_permissions.rb),
  # the same list GET /permissions sends the apps, so policies ask it rather than the role name
  def permitted?(tag)
    accounts_shopkeeper.permission_tags.include?(tag.to_s)
  end
end
