class ApplicationPushDeviceResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :platform
  attribute :token
  attribute :name
  attribute :bundle_id
  attribute :last_active_at, form: false
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :owner

  # Customize the default sort column and direction.
  def self.default_sort_column = "last_active_at"

  def self.default_sort_direction = "desc"
end
