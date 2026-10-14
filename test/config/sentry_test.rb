require "test_helper"
require "sentry/test_helper"

# config/initializers/sentry.rb: Sentry stays off without SENTRY_DSN, and an
# event leaves without credentials or email addresses.
class SentryTest < ActiveSupport::TestCase
  include Sentry::TestHelper

  # Read when this file loads, right after the app booted and before any test
  # here calls init or Sentry.close, so test order can't hide a boot-time init.
  INITIALIZED_AT_BOOT = Sentry.initialized?

  teardown do
    teardown_sentry_test
    Sentry.close if Sentry.initialized?
  end

  # Without a DSN

  test "the app boots without initialising Sentry when SENTRY_DSN is not set" do
    assert_nil ENV["SENTRY_DSN"], "the test environment must not have a DSN"
    refute INITIALIZED_AT_BOOT
  end

  test "init does nothing without a DSN" do
    [nil, "", "  "].each do |dsn|
      refute NativeapptemplateSentry.init(dsn), "init(#{dsn.inspect}) must return false"
      refute Sentry.initialized?, "init(#{dsn.inspect}) must not initialise Sentry"
    end
  end

  test "capturing without a DSN is a no-op" do
    assert_nil Sentry.capture_exception(RuntimeError.new("boom"))
    assert_nil Sentry.set_user(id: "id")
  end

  # With a DSN

  test "init with a DSN configures Sentry for production only and without personal data" do
    assert NativeapptemplateSentry.init(Sentry::TestHelper::DUMMY_DSN)
    assert Sentry.initialized?

    config = Sentry.configuration
    assert_equal "test", config.environment
    assert_equal %w[production], config.enabled_environments
    refute config.enabled_in_current_env?, "events must not be sent from the test environment"
    refute config.send_default_pii
    refute config.data_collection.user_info
    assert_empty config.data_collection.http_bodies, "request bodies must not be collected"
    assert_equal :off, config.data_collection.url_query_params.mode
    assert_equal :off, config.data_collection.cookies.mode
    # nil, not 0.0: a rate of 0.0 still counts as tracing enabled in production
    assert_nil config.traces_sample_rate
    assert_nil config.traces_sampler
    assert_nil config.profiles_sample_rate
    assert_empty config.breadcrumbs_logger
  end

  test "expected 4xx exceptions are excluded and real bugs are not" do
    NativeapptemplateSentry.init(Sentry::TestHelper::DUMMY_DSN)
    config = Sentry.configuration

    record = Shopkeeper.new
    excluded = [
      ActiveRecord::RecordInvalid.new(record),
      ActiveRecord::RecordNotDestroyed.new("halted", record),
      Pundit::NotAuthorizedError.new("denied"),
      # sentry-rails defaults, kept
      ActiveRecord::RecordNotFound.new("missing"),
      ActionController::RoutingError.new("no route"),
      ActionController::ParameterMissing.new(:shop)
    ]
    excluded.each do |exception|
      refute config.exception_class_allowed?(exception), "#{exception.class} must not be sent"
    end

    assert config.exception_class_allowed?(RuntimeError.new("bug"))
    assert config.exception_class_allowed?(NoMethodError.new("bug"))
    assert config.exception_class_allowed?(ActiveRecord::StatementInvalid.new("bug"))
  end

  # before_send

  test "before_send drops devise_token_auth headers and masks email addresses" do
    NativeapptemplateSentry.init(Sentry::TestHelper::DUMMY_DSN)
    setup_sentry_test

    env = Rack::MockRequest.env_for("https://api.nativeapptemplate.com/api/v1/shopkeeper/shops?email=owner@example.com",
      "HTTP_AUTHORIZATION" => "Bearer secret",
      "HTTP_ACCESS_TOKEN" => "the-access-token",
      "HTTP_CLIENT" => "the-client-id",
      "HTTP_UID" => "owner@example.com",
      "HTTP_EXPIRY" => "1760000000",
      "HTTP_TOKEN_TYPE" => "Bearer",
      "HTTP_ACCEPT" => "application/json")

    Sentry.with_scope do |scope|
      scope.set_rack_env(env)
      Sentry.set_extras(email: "owner@example.com", count: 3)
      Sentry.capture_exception(RuntimeError.new("No shop for owner@example.com and staff.member+1@shop.co.jp"))
    end

    event = last_sentry_event
    assert event, "the event must be sent"

    headers = event.request.headers
    %w[Authorization Access-Token Client Uid Expiry Token-Type].each do |name|
      refute headers.key?(name), "#{name} must be dropped, got #{headers.keys.inspect}"
    end
    # Unrelated headers stay
    assert_equal "application/json", headers["Accept"]

    # detailed_message appends " (RuntimeError)"
    assert_equal "No shop for [FILTERED EMAIL] and [FILTERED EMAIL] (RuntimeError)", event.exception.values.last.value
    assert_equal "[FILTERED]", event.extra[:email], "filter_parameters must apply to extras"
    assert_equal 3, event.extra[:count]

    json = event.to_json_compatible.to_json
    refute_includes json, "owner@example.com"
    refute_includes json, "staff.member+1@shop.co.jp"
    refute_includes json, "the-access-token"
    refute_includes json, "the-client-id"
  end

  test "before_send masks email addresses in a captured message" do
    NativeapptemplateSentry.init(Sentry::TestHelper::DUMMY_DSN)
    setup_sentry_test

    Sentry.capture_message("Invitation failed for invitee@example.com")

    assert_equal "Invitation failed for [FILTERED EMAIL]", last_sentry_event.message
  end

  test "before_send filters request data with filter_parameters" do
    event = Sentry::ErrorEvent.new(configuration: Sentry::Configuration.new)
    event.instance_variable_set(:@request, Sentry::RequestInterface.allocate)
    event.request.data = {"email" => "owner@example.com", "password" => "secret", "shop" => {"name" => "My shop", "description" => "ok"}}
    event.request.query_string = {"email" => "owner@example.com", "page" => "2"}

    NativeapptemplateSentry.scrub(event)

    assert_equal({"email" => "[FILTERED]", "password" => "[FILTERED]", "shop" => {"name" => "[FILTERED]", "description" => "ok"}}, event.request.data)
    assert_equal({"email" => "[FILTERED]", "page" => "2"}, event.request.query_string)
  end
end
