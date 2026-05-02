admin_role = Role.find_by(tag: "admin")
member_role = Role.find_by(tag: "member")

create_shops_permission = Permission.find_by(tag: "create_shops")
update_shops_permission = Permission.find_by(tag: "update_shops")
delete_shops_permission = Permission.find_by(tag: "delete_shops")
update_organizations_permission = Permission.find_by(tag: "update_organizations")
invitation_permission = Permission.find_by(tag: "invitation")
read_data_permission = Permission.find_by(tag: "read_data")

RolesPermission.seed(
  :role_id, :permission_id,
  # admin: all permissions
  {role_id: admin_role.id, permission_id: create_shops_permission.id},
  {role_id: admin_role.id, permission_id: update_shops_permission.id},
  {role_id: admin_role.id, permission_id: delete_shops_permission.id},
  {role_id: admin_role.id, permission_id: update_organizations_permission.id},
  {role_id: admin_role.id, permission_id: invitation_permission.id},
  {role_id: admin_role.id, permission_id: read_data_permission.id},
  # member: CRUD on shops + read_data (no organization management or invitation)
  {role_id: member_role.id, permission_id: create_shops_permission.id},
  {role_id: member_role.id, permission_id: update_shops_permission.id},
  {role_id: member_role.id, permission_id: delete_shops_permission.id},
  {role_id: member_role.id, permission_id: read_data_permission.id}
)
