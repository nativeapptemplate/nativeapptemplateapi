class TermsVersion < ApplicationRecord
  enum :current_type, {uncurrent: 1, current: 2}

  def self.current_version
    TermsVersion
      .current
      .order(version: :desc)
      .first
      .version
  end
end
