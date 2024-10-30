shopkeeper = Shopkeeper.first

Shop.seed(:account_id, :created_by_id, :name) do |s|
  name = "Shop1"
  s.account_id = shopkeeper.personal_account.id
  s.created_by_id = shopkeeper.id
  s.name = name
  s.time_zone = "Tokyo"
  s.description = "This is a #{name} created by #{shopkeeper.name}."
end
