ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

# Uncomment to view full stack trace in tests
# Rails.backtrace_cleaner.remove_silencers!

if defined?(SolidQueue)
  SolidQueue.logger.level = Logger::WARN
end

module ActiveSupport
  class TestCase
    setup do
      Dir[Rails.root.join("db", "fixtures", "test", "*.rb")].sort.each { |s| load s }
    end

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def json_response
      JSON.decode(response.body)
    end
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers

    def switch_account(account)
      patch "/accounts/#{account.id}/switch"
    end
  end
end

WebMock.disable_net_connect!({
  allow_localhost: true,
  allow: [
    "chromedriver.storage.googleapis.com",
    "rails-app",
    "selenium"
  ]
})
