class Role < ApplicationRecord
  has_many :roles_permissions, dependent: :destroy
  has_many :permissions, through: :roles_permissions
end
