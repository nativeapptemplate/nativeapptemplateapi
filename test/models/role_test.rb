require "test_helper"

class RoleTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    role = Role.new(
      name: "Test Role",
      tag: "test_role",
      position: 100
    )
    assert role.valid?
  end

  test "should have many roles_permissions" do
    role = Role.first
    assert_respond_to role, :roles_permissions
  end

  test "should have many permissions through roles_permissions" do
    role = Role.first
    assert_respond_to role, :permissions
  end

  test "should destroy associated roles_permissions when destroyed" do
    role = Role.create!(
      name: "Test Role",
      tag: "test_role_destroy",
      position: 999
    )

    permission = Permission.first
    RolesPermission.create!(role: role, permission: permission)

    assert_difference "RolesPermission.count", -1 do
      role.destroy
    end
  end

  test "should be associated with permissions through roles_permissions" do
    admin_role = Role.find_by(tag: "admin")
    update_shops_permission = Permission.find_by(tag: "update_shops")

    assert_includes admin_role.permissions, update_shops_permission
  end

  test "should load from fixtures" do
    assert Role.count > 0

    admin_role = Role.find_by(tag: "admin")
    assert_not_nil admin_role
    assert_equal "admin", admin_role.name
  end

  test "admin role should have all permissions" do
    admin_role = Role.find_by(tag: "admin")
    assert admin_role.permissions.count > 0
    assert_includes admin_role.permissions.pluck(:tag), "update_shops"
    assert_includes admin_role.permissions.pluck(:tag), "invitation"
  end

  test "member role should have minimal permissions" do
    member_role = Role.find_by(tag: "member")
    assert member_role.permissions.count > 0

    read_data_permission = Permission.find_by(tag: "read_data")
    assert_includes member_role.permissions, read_data_permission
  end

  test "roles should be ordered by position" do
    admin = Role.find_by(tag: "admin")
    member = Role.find_by(tag: "member")

    assert admin.position < member.position
  end
end
