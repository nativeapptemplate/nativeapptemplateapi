admin_role = Role.find_by(tag: "admin")
senior_manager_role = Role.find_by(tag: "senior_manager")
junior_manager_role = Role.find_by(tag: "junior_manager")
senior_member_role = Role.find_by(tag: "senior_member")
junior_member_role = Role.find_by(tag: "junior_member")
guest_role = Role.find_by(tag: "guest")

update_shops_permission = Permission.find_by(tag: "update_shops")
update_organizations_permission = Permission.find_by(tag: "update_organizations")
invitation_permission = Permission.find_by(tag: "invitation")
read_data_permission = Permission.find_by(tag: "read_data")

RolesPermission.seed(
  :role_id, :permission_id,
  {role_id: admin_role.id, permission_id: update_shops_permission.id},
  {role_id: admin_role.id, permission_id: update_organizations_permission.id},
  {role_id: admin_role.id, permission_id: invitation_permission.id},
  {role_id: admin_role.id, permission_id: read_data_permission.id},
  {role_id: senior_manager_role.id, permission_id: read_data_permission.id},
  {role_id: junior_manager_role.id, permission_id: read_data_permission.id},
  {role_id: senior_member_role.id, permission_id: read_data_permission.id},
  {role_id: junior_member_role.id, permission_id: read_data_permission.id},
  {role_id: guest_role.id, permission_id: read_data_permission.id}
)
