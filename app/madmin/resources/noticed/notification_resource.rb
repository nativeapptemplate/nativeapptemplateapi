class Noticed::NotificationResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :type
  attribute :read_at
  attribute :seen_at
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :event
  attribute :recipient

  # Customize the default sort column and direction.
  def self.default_sort_column = "created_at"

  def self.default_sort_direction = "desc"
end
