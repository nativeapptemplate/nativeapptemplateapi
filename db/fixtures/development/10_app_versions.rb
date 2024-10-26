require "csv"

CSV.parse(File.readlines("db/data/app_versions.csv").drop(2).join) do |row|
  AppVersion.seed(:platform, :version) do |app_version|
    app_version.platform = row[0]
    app_version.version = row[1].to_i
    app_version.current_type = row[2].to_i
    app_version.forced_update_type = row[3].to_i
    app_version.title = row[4]
    app_version.description = row[5]
  end
end
