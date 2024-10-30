class AccountsShopkeeperResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :admin
  attribute :senior_manager
  attribute :junior_manager
  attribute :senior_member
  attribute :junior_member
  attribute :guest

  # Associations
  attribute :account
  attribute :shopkeeper

  # Uncomment this to customize the display name of records in the admin area.
  # def self.display_name(record)
  #   record.name
  # end

  # Uncomment this to customize the default sort column and direction.
  # def self.default_sort_column
  #   "created_at"
  # end
  #
  # def self.default_sort_direction
  #   "desc"
  # end
end
