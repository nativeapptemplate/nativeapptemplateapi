namespace :role_redesign do
  desc "Fold legacy 7-role data to admin/member and delete orphan role/permission rows. Idempotent."
  task migrate: :environment do
    old_role_tags = %w[senior_manager junior_manager senior_member junior_member guest]
    old_permission_tags = %w[manage_tags write_info_to_tags reset_all_tags complete_or_reset_tags show_tag_info]

    ApplicationRecord.transaction do
      [AccountsShopkeeper, AccountsInvitation].each do |klass|
        remap_count = 0
        klass.find_each do |record|
          new_roles = record.roles["admin"] ? {"admin" => true} : {"member" => true}
          next if record.roles == new_roles

          puts "#{klass.name} #{record.id}: #{record.roles.inspect} -> #{new_roles.inspect}"
          record.update_columns(roles: new_roles)
          remap_count += 1
        end
        puts "#{klass.name}: remapped #{remap_count} record(s)."
      end

      old_role_ids = Role.where(tag: old_role_tags).pluck(:id)
      old_permission_ids = Permission.where(tag: old_permission_tags).pluck(:id)

      rp_count = RolesPermission
        .where(role_id: old_role_ids)
        .or(RolesPermission.where(permission_id: old_permission_ids))
        .delete_all
      role_count = Role.where(id: old_role_ids).delete_all
      perm_count = Permission.where(id: old_permission_ids).delete_all

      puts "Deleted #{rp_count} roles_permissions, #{role_count} roles, #{perm_count} permissions."
    end

    puts "Done."
  end
end
