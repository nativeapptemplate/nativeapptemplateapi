require "test_helper"
require "rake"

class RoleRedesignTaskTest < ActiveSupport::TestCase
  TASK_NAME = "role_redesign:migrate"

  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?(TASK_NAME)
    Rake::Task[TASK_NAME].reenable

    @owner = shopkeepers(:one)
    @owner.create_default_account
    @account = @owner.accounts.first
    @other = shopkeepers(:two)
  end

  test "folds shopkeeper with old role keys to member" do
    accounts_shopkeeper = AccountsShopkeeper.create!(account: @account, shopkeeper: @other, member: true)
    accounts_shopkeeper.update_columns(roles: {"senior_manager" => true, "guest" => true})

    silence_stream($stdout) { Rake::Task[TASK_NAME].invoke }

    assert_equal({"member" => true}, accounts_shopkeeper.reload.roles)
  end

  test "preserves admin even when legacy roles are also set" do
    accounts_shopkeeper = AccountsShopkeeper.create!(account: @account, shopkeeper: @other, member: true)
    accounts_shopkeeper.update_columns(roles: {"admin" => true, "senior_member" => true})

    silence_stream($stdout) { Rake::Task[TASK_NAME].invoke }

    assert_equal({"admin" => true}, accounts_shopkeeper.reload.roles)
  end

  test "leaves already-migrated rows untouched" do
    accounts_shopkeeper = AccountsShopkeeper.create!(account: @account, shopkeeper: @other, admin: true)
    before_updated_at = accounts_shopkeeper.updated_at

    silence_stream($stdout) { Rake::Task[TASK_NAME].invoke }

    accounts_shopkeeper.reload
    assert_equal({"admin" => true}, accounts_shopkeeper.roles)
    assert_equal before_updated_at.to_i, accounts_shopkeeper.updated_at.to_i
  end

  test "folds invitations with old role keys to member" do
    invitation = AccountsInvitation.create!(account: @account, name: "Invitee", email: "invitee@example.com", member: true)
    invitation.update_columns(roles: {"junior_manager" => true})

    silence_stream($stdout) { Rake::Task[TASK_NAME].invoke }

    assert_equal({"member" => true}, invitation.reload.roles)
  end

  test "treats empty roles hash as member" do
    accounts_shopkeeper = AccountsShopkeeper.create!(account: @account, shopkeeper: @other, member: true)
    accounts_shopkeeper.update_columns(roles: {})

    silence_stream($stdout) { Rake::Task[TASK_NAME].invoke }

    assert_equal({"member" => true}, accounts_shopkeeper.reload.roles)
  end

  test "deletes orphan roles, permissions, and roles_permissions" do
    senior_manager = Role.create!(tag: "senior_manager", name: "senior manager", position: 99)
    manage_tags = Permission.create!(tag: "manage_tags", name: "manage tags", position: 99)
    RolesPermission.create!(role: senior_manager, permission: manage_tags)
    RolesPermission.create!(role: senior_manager, permission: Permission.find_by!(tag: "read_data"))
    RolesPermission.create!(role: Role.find_by!(tag: "admin"), permission: manage_tags)

    silence_stream($stdout) { Rake::Task[TASK_NAME].invoke }

    assert_nil Role.find_by(tag: "senior_manager")
    assert_nil Permission.find_by(tag: "manage_tags")
    assert_equal 0, RolesPermission.where(role_id: senior_manager.id).count
    assert_equal 0, RolesPermission.where(permission_id: manage_tags.id).count
    assert Role.find_by(tag: "admin"), "admin role must remain"
    assert Permission.find_by(tag: "read_data"), "read_data permission must remain"
  end

  test "is idempotent on re-run" do
    accounts_shopkeeper = AccountsShopkeeper.create!(account: @account, shopkeeper: @other, member: true)
    accounts_shopkeeper.update_columns(roles: {"junior_member" => true})
    Role.create!(tag: "guest", name: "guest", position: 99)

    silence_stream($stdout) { Rake::Task[TASK_NAME].invoke }
    Rake::Task[TASK_NAME].reenable
    assert_nothing_raised { silence_stream($stdout) { Rake::Task[TASK_NAME].invoke } }

    assert_equal({"member" => true}, accounts_shopkeeper.reload.roles)
    assert_nil Role.find_by(tag: "guest")
  end

  private

  def silence_stream(stream)
    old_stream = stream.dup
    stream.reopen(File::NULL)
    stream.sync = true
    yield
  ensure
    stream.reopen(old_stream)
    old_stream.close
  end
end
