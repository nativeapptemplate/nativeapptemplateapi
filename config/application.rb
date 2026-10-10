require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Nativeapptemplateapi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[middleware tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Use ErrorsController for handling 404s and 500s.
    config.exceptions_app = routes

    # Where the I18n library should search for translation files
    # Search nested folders in config/locales for better organization
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.{rb,yml}")]

    # Permitted locales available for the application
    config.i18n.available_locales = [:en]

    # Set default locale
    config.i18n.default_locale = :en

    # Use default language as fallback if translation is missing
    config.i18n.fallbacks = true

    config.active_model.i18n_customize_full_message = true

    # https://github.com/heartcombo/devise/issues/4825
    config.wrap_parameters = false

    # Cloudflare fronts the origin, so request.remote_ip must resolve past its
    # edge to the caller (config/cloudflare_ips.yml explains what reads it and
    # why: Rails' rate_limit keys on remote_ip). `+`, not `=`: assigning would
    # drop the loopback and private ranges Rails trusts by default, and
    # kamal-proxy reaches the container over exactly such an address.
    config.action_dispatch.trusted_proxies =
      ActionDispatch::RemoteIp::TRUSTED_PROXIES +
      YAML.load_file(Rails.root.join("config/cloudflare_ips.yml")).values.flatten.map { |range| IPAddr.new(range) }

    require "middleware/account_middleware"
    config.middleware.use AccountMiddleware

    # Mission Control's own HTTP Basic auth is off: AdminConstraint in routes.rb
    # guards /madmin/jobs. This must be set here, not in config/initializers,
    # because the engine copies config.mission_control.jobs into its settings
    # before the app's initializers run.
    config.mission_control.jobs.http_basic_auth_enabled = false
  end
end
