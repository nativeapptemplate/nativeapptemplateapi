class PrivacyVersion < ApplicationRecord
  enum :current_type, {uncurrent: 1, current: 2}

  def self.current_version
    current
      .order(version: :desc)
      .first
      &.version
  end
end
