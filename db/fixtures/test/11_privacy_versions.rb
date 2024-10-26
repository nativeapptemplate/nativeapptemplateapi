require "csv"

CSV.parse(File.readlines("db/data/privacy_versions.csv").drop(2).join) do |row|
  PrivacyVersion.seed(:version) do |privacy_version|
    privacy_version.version = row[0].to_i
    privacy_version.current_type = row[1].to_i
    privacy_version.published_at = row[2]
    privacy_version.title = row[3]
    privacy_version.description = row[4]
  end
end
