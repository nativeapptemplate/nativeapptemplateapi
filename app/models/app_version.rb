class AppVersion < ApplicationRecord
  enum :current_type, {uncurrent: 1, current: 2}
  enum :forced_update_type, {unforced_update: 1, forced_update: 2}

  def self.current_version(platform:)
    AppVersion
      .current
      .where(platform: platform)
      .order(version: :desc)
      .first
      .version
  end
end
