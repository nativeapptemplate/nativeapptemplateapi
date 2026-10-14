require "test_helper"
require "sentry/test_helper"

# An error inside a shopkeeper request reaches Sentry with the shopkeeper's ID
# (and nothing else about them) and the current account's ID; handled 4xx
# answers do not reach Sentry at all (config/initializers/sentry.rb,
# SetCurrentRequestDetails).
class SentryContextTest < ActionDispatch::IntegrationTest
  include Sentry::TestHelper

  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first

    NativeapptemplateSentry.init(Sentry::TestHelper::DUMMY_DSN)
    setup_sentry_test
  end

  teardown do
    teardown_sentry_test
    Sentry.close if Sentry.initialized?
  end

  test "an unhandled error is sent with the shopkeeper's id only and the account id" do
    email = @shopkeeper.email
    PrivacyVersion.stub(:current_version, -> { raise "privacy lookup failed for #{email}" }) do
      assert_raises(RuntimeError) do
        get "/#{@account.id}/api/v1/shopkeeper/permissions", headers: @shopkeeper.create_new_auth_token
      end
    end

    event = last_sentry_event
    assert event, "the error must be sent"
    assert_equal({id: @shopkeeper.id}, event.user)
    assert_equal @account.id, event.tags[:account_id]
    # detailed_message appends " (RuntimeError)"
    assert_equal "privacy lookup failed for [FILTERED EMAIL] (RuntimeError)", event.exception.values.last.value

    json = event.to_json_compatible.to_json
    refute_includes json, email
    refute_includes json, @shopkeeper.name if @shopkeeper.name.present?
    %w[Access-Token Client Uid Authorization].each do |header|
      refute event.request.headers.key?(header), "#{header} must not be sent"
    end
  end

  test "a 401 for a request without a signed-in shopkeeper is not sent" do
    get "/api/v1/shopkeeper/permissions"

    assert_response :unauthorized
    assert_empty sentry_events, "a 401 is not a bug"
  end

  test "handled 4xx answers are not sent" do
    headers = @shopkeeper.create_new_auth_token

    get "/#{@account.id}/api/v1/shopkeeper/shops/00000000-0000-0000-0000-000000000000", headers: headers
    assert_response :not_found

    get "/00000000-0000-0000-0000-000000000000/api/v1/shopkeeper/shops", headers: headers
    assert_response :not_found

    assert_empty sentry_events
  end
end
