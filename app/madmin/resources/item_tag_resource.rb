class ItemTagResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :queue_number
  attribute :state
  attribute :customer_read_at
  attribute :completed_at
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :scan_state
  attribute :already_completed

  # Associations
  attribute :account
  attribute :shop
  attribute :created_by
  attribute :completed_by

  # Add scopes to easily filter records
  # scope :published

  # Add actions to the resource's show page
  # member_action do |record|
  #   link_to "Do Something", some_path
  # end

  # Customize the display name of records in the admin area.
  # def self.display_name(record) = record.name

  # Customize the default sort column and direction.
  # def self.default_sort_column = "created_at"
  #
  # def self.default_sort_direction = "desc"
end
