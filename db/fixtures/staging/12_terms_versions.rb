require "csv"

CSV.parse(File.readlines("db/data/terms_versions.csv").drop(2).join) do |row|
  TermsVersion.seed(:version) do |terms_version|
    terms_version.version = row[0].to_i
    terms_version.current_type = row[1].to_i
    terms_version.published_at = row[2]
    terms_version.title = row[3]
    terms_version.description = row[4]
  end
end
