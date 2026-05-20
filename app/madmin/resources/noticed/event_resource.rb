class Noticed::EventResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :type
  attribute :params
  attribute :notifications_count, form: false
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :record
  attribute :notifications

  # Customize the default sort column and direction.
  def self.default_sort_column = "created_at"

  def self.default_sort_direction = "desc"
end
