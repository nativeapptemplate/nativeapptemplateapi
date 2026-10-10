require "test_helper"
require "open3"

# Confirmation and password reset emails link back to the API host.
#
# Booting the production environment needs its credentials key, which only
# developer machines have, so this skips in CI.
class MailerHostTest < ActiveSupport::TestCase
  test "production emails link to the production API domain" do
    skip "needs config/credentials/production.key" unless Rails.root.join("config/credentials/production.key").exist?

    assert_equal({host: ConfigSettings.app.domain, protocol: "https"}, mailer_url_options("production"))
  end

  private

  def mailer_url_options(env)
    db = ActiveRecord::Base.connection_db_config.configuration_hash
    db_url = "postgres://#{db[:username] || ENV.fetch("USER")}@#{db[:host] || "localhost"}/#{db[:database]}"
    vars = {
      "RAILS_ENV" => env,
      "DATABASE_URL" => db_url, "CACHE_DATABASE_URL" => db_url,
      "QUEUE_DATABASE_URL" => db_url, "CABLE_DATABASE_URL" => db_url
    }

    out, status = Open3.capture2e(vars, "bin/rails", "runner", "puts ActionMailer::Base.default_url_options.to_json", chdir: Rails.root)
    assert status.success?, out
    JSON.parse(out.lines.last, symbolize_names: true)
  end
end
