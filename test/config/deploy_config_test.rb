require "test_helper"

# config/deploy.yml, .kamal/secrets, config/database.yml and the Dockerfile
# describe one deployment between them, and nothing checks them against each
# other until the first `kamal deploy`. These checks keep the halves in step.
class DeployConfigTest < ActiveSupport::TestCase
  DEPLOY = YAML.load_file(Rails.root.join("config/deploy.yml"))
  SERVICE = "nativeapptemplateapi"

  # The accessory boots Postgres with POSTGRES_USER / POSTGRES_DB; Active Record
  # connects with database.yml's production username / database. They must agree
  # or the first db:prepare fails with "role does not exist".
  test "db accessory creates the role and database that database.yml connects to" do
    db = ActiveRecord::Base.configurations.configs_for(env_name: "production", name: "primary").configuration_hash
    accessory_env = DEPLOY.dig("accessories", "db", "env", "clear")

    assert_equal db[:username], accessory_env["POSTGRES_USER"]
    assert_equal db[:database], accessory_env["POSTGRES_DB"]
  end

  # Kamal names an accessory container "<service>-<accessory>" and the app
  # reaches it by that name on the kamal Docker network (Kamal docs: Accessories).
  test "DB_HOST is the db accessory's container name" do
    assert_equal "#{DEPLOY["service"]}-db", DEPLOY.dig("env", "clear", "DB_HOST")
    assert_equal SERVICE, DEPLOY["service"]
  end

  # database.yml reads POSTGRES_PASSWORD and DB_HOST; both must arrive in the
  # app container, and the accessory needs the same password.
  test "app and db accessory receive the Postgres password" do
    assert_includes DEPLOY.dig("env", "secret"), "POSTGRES_PASSWORD"
    assert_includes DEPLOY.dig("env", "secret"), "RAILS_MASTER_KEY"
    assert_includes DEPLOY.dig("accessories", "db", "env", "secret"), "POSTGRES_PASSWORD"
  end

  # Kamal resolves every env.secret, registry password and accessory secret from
  # .kamal/secrets; an unknown name aborts the deploy.
  test ".kamal/secrets defines every secret deploy.yml references" do
    defined = File.readlines(Rails.root.join(".kamal/secrets")).filter_map { |line| line[/\A([A-Z0-9_]+)=/, 1] }
    referenced = DEPLOY.dig("env", "secret") + DEPLOY.dig("registry", "password") +
      DEPLOY.dig("accessories", "db", "env", "secret") + DEPLOY.dig("proxy", "ssl").values

    assert_empty referenced - defined
  end

  test "images are pushed to GitHub Container Registry" do
    assert_equal "ghcr.io", DEPLOY.dig("registry", "server")
    assert_match %r{\A[\w-]+/#{SERVICE}\z}, DEPLOY["image"]
  end

  # Jobs and config/recurring.yml run inside Puma; without this flag and with no
  # job server, nothing would process the queue.
  test "Solid Queue runs in Puma because there is no job server" do
    assert_equal true, DEPLOY.dig("env", "clear", "SOLID_QUEUE_IN_PUMA")
    assert_nil DEPLOY.dig("servers", "job")
  end

  # proxy.host is what kamal-proxy routes and gets a certificate for; Rails
  # rejects any other Host header (config.hosts in production.rb).
  test "proxy host is the API domain Rails accepts" do
    assert_equal ConfigSettings.app.domain, DEPLOY.dig("proxy", "host")
  end

  # Active Storage's :local service writes under storage/ (config/storage.yml),
  # which is /rails/storage in the image; without a volume uploads vanish on deploy.
  test "Active Storage files live on a persistent volume" do
    assert_includes DEPLOY["volumes"], "#{SERVICE}_storage:/rails/storage"
  end

  # The Postgres accessory only publishes a host port for server-side admin work;
  # a bare "5432:5432" would bind 0.0.0.0 and expose the database.
  test "db accessory is published on loopback only" do
    assert_match %r{\A127\.0\.0\.1:\d+:5432\z}, DEPLOY.dig("accessories", "db", "port")
  end

  # The image must match the server's CPU, or the container dies with "exec
  # format error" after a successful push. Kamal's default and most VPS plans are
  # x86; a deliberate change to arm64 for an ARM box should update this too.
  test "image is built for x86 servers" do
    assert_equal "amd64", DEPLOY.dig("builder", "arch")
  end

  test "Dockerfile builds the Ruby in .ruby-version" do
    ruby_version = Rails.root.join(".ruby-version").read.strip
    dockerfile = Rails.root.join("Dockerfile").read

    assert_includes dockerfile, "ARG RUBY_VERSION=#{ruby_version}"
  end

  # bin/setup and CI install gems into vendor/bundle for the host platform; copying
  # them into the image breaks `bundle install` there and bloats the image.
  test "Docker build context excludes vendor/bundle" do
    assert_includes Rails.root.join(".dockerignore").readlines.map(&:strip), "/vendor/bundle"
  end
end
