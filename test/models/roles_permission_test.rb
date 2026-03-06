require "test_helper"

class RolesPermissionTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    role = Role.first
    permission = Permission.first

    roles_permission = RolesPermission.new(
      role: role,
      permission: permission
    )

    assert roles_permission.valid?
  end

  test "should belong to role" do
    roles_permission = RolesPermission.first
    assert_respond_to roles_permission, :role
    assert_instance_of Role, roles_permission.role
  end

  test "should belong to permission" do
    roles_permission = RolesPermission.first
    assert_respond_to roles_permission, :permission
    assert_instance_of Permission, roles_permission.permission
  end

  test "should require role" do
    permission = Permission.first
    roles_permission = RolesPermission.new(permission: permission)

    assert_not roles_permission.valid?
    assert_includes roles_permission.errors[:role], "must exist"
  end

  test "should require permission" do
    role = Role.first
    roles_permission = RolesPermission.new(role: role)

    assert_not roles_permission.valid?
    assert_includes roles_permission.errors[:permission], "must exist"
  end

  test "should load from fixtures" do
    assert RolesPermission.count > 0

    admin_role = Role.find_by(tag: "admin")
    update_shops = Permission.find_by(tag: "update_shops")

    roles_permission = RolesPermission.find_by(
      role: admin_role,
      permission: update_shops
    )

    assert_not_nil roles_permission
  end

  test "should create association between role and permission" do
    role = Role.create!(name: "Test Role", tag: "test_role_assoc", position: 100)
    permission = Permission.create!(name: "Test Permission", tag: "test_perm_assoc", position: 100)

    RolesPermission.create!(role: role, permission: permission)

    assert_includes role.permissions, permission
    assert_includes permission.roles, role
  end
end
