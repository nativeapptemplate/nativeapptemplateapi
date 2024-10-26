10.times do |i|
  id = i + 1
  AdminUser.seed(:email) do |a|
    a.name = "admin_user#{id}"
    a.email = "admin_user#{id}@example.com"
    a.password = "password"
    a.password_confirmation = "password"
  end
end
