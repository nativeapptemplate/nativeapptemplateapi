require "test_helper"

class PermissionTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    permission = Permission.new(
      name: "Test Permission",
      tag: "test_permission",
      position: 100
    )
    assert permission.valid?
  end

  test "should have many roles_permissions" do
    permission = Permission.first
    assert_respond_to permission, :roles_permissions
  end

  test "should have many roles through roles_permissions" do
    permission = Permission.first
    assert_respond_to permission, :roles
  end

  test "should destroy associated roles_permissions when destroyed" do
    permission = Permission.create!(
      name: "Test Permission",
      tag: "test_permission_destroy",
      position: 999
    )

    role = Role.first
    RolesPermission.create!(role: role, permission: permission)

    assert_difference "RolesPermission.count", -1 do
      permission.destroy
    end
  end

  test "should be associated with roles through roles_permissions" do
    permission = Permission.find_by(tag: "update_shops")
    admin_role = Role.find_by(tag: "admin")

    assert_includes permission.roles, admin_role
  end

  test "should load from fixtures" do
    assert Permission.count > 0

    permission = Permission.find_by(tag: "update_shops")
    assert_not_nil permission
    assert_equal "update shops", permission.name
  end
end
