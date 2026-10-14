# Error monitoring with Sentry (sentry-ruby + sentry-rails). Optional.
#
# OFF UNLESS SENTRY_DSN IS SET. Without a DSN, Sentry.init is never called:
# the SDK stays uninitialised, its middleware passes requests through and
# Sentry.set_user / capture_exception are no-ops. Development and test run
# like that. In production the DSN comes in as a Kamal secret
# (config/deploy.yml, .kamal/secrets); README "Error monitoring (Sentry)".
#
# ONLY REAL BUGS. Sentry's free plan allows 5,000 errors a month, so expected
# failures stay out: everything the API answers with a 4xx through rescue_from
# (Api::V1::Shopkeeper::BaseController) never reaches Sentry, and the 4xx
# exceptions Rails turns into responses itself are listed in
# EXPECTED_EXCEPTIONS below (on top of sentry-rails' defaults such as
# ActiveRecord::RecordNotFound, ActionController::RoutingError and
# ActionController::ParameterMissing).
#
# NO PERSONAL DATA. Events carry the shopkeeper's ID and the current account's
# ID (SetCurrentRequestDetails), never an email or a name. send_default_pii is
# off, so request bodies, query strings, cookies and IP addresses are not
# collected; before_send additionally drops the devise_token_auth headers,
# masks anything that looks like an email address, and runs
# Rails.application.config.filter_parameters over the request data and extras.
module NativeapptemplateSentry
  # devise_token_auth's credentials, request and response side
  AUTH_HEADERS = %w[authorization access-token client uid expiry token-type].freeze

  EMAIL_PATTERN = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/
  EMAIL_REPLACEMENT = "[FILTERED EMAIL]"

  # 4xx answers, not bugs. Pundit::NotAuthorizedError and RecordNotDestroyed
  # are rescued in Api::V1::Shopkeeper::BaseController, but listed in case
  # they are raised elsewhere; RecordInvalid (update!/create! on invalid
  # input) becomes a 422 through Rails' rescue_responses. Add new expected
  # exceptions here rather than letting them reach Sentry.
  EXPECTED_EXCEPTIONS = %w[
    ActiveRecord::RecordInvalid
    ActiveRecord::RecordNotDestroyed
    Pundit::NotAuthorizedError
  ].freeze

  module_function

  # Returns true when Sentry was initialised.
  def init(dsn)
    return false if dsn.blank?

    Sentry.init do |config|
      config.dsn = dsn
      config.environment = Rails.env
      # Events are only sent from production; any other environment with a
      # DSN initialises the SDK but sends nothing.
      config.enabled_environments = %w[production]
      # release is detected by the SDK: SENTRY_RELEASE, then KAMAL_VERSION
      # (the deployed git SHA, set by Kamal in the container), then git.

      config.send_default_pii = false
      # Errors only. traces_sample_rate and profiles_sample_rate stay nil,
      # which turns tracing and profiling off entirely (0.0 would still start
      # an unsampled transaction per request). No breadcrumbs either: an SQL
      # or log breadcrumb could carry personal data.
      config.traces_sample_rate = nil
      config.profiles_sample_rate = nil
      config.breadcrumbs_logger = []

      config.excluded_exceptions += EXPECTED_EXCEPTIONS
      config.before_send = ->(event, hint) { scrub(event, hint) }
    end

    true
  end

  def scrub(event, _hint = nil)
    if (request = event.request)
      request.headers = request.headers&.reject { |name, _| AUTH_HEADERS.include?(name.to_s.downcase) }
      request.data = parameter_filter.filter(request.data) if request.data.is_a?(Hash)
      request.query_string = parameter_filter.filter(request.query_string) if request.query_string.is_a?(Hash)
      request.url = mask_emails(request.url)
    end

    event.message = mask_emails(event.message) if event.message.is_a?(String)
    event.exception&.values&.each { |exception| exception.value = mask_emails(exception.value) }
    event.extra = parameter_filter.filter(event.extra) if event.extra.present?

    event
  end

  def mask_emails(text)
    text.is_a?(String) ? text.gsub(EMAIL_PATTERN, EMAIL_REPLACEMENT) : text
  end

  def parameter_filter
    ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
  end
end

NativeapptemplateSentry.init(ENV["SENTRY_DSN"])
