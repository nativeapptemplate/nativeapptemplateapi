10.times do |i|
  id = i + 1
  Shopkeeper.seed(:email) do |s|
    s.name = "shopkeeper#{id}"
    s.email = "shopkeeper#{id}@example.com"
    s.password = "password"
    s.password_confirmation = "password"
    s.time_zone = "Tokyo"
    s.current_platform = "ios"
    s.confirmed_privacy_version = 1
    s.confirmed_terms_version = 1
  end
end

Shopkeeper.all.each do |s|
  confirmation_token = s.confirmation_token
  Shopkeeper.confirm_by_token(confirmation_token)
end
