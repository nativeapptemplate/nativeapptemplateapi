require "test_helper"

# kamal-proxy only routes traffic to a container once GET /up answers 2xx/3xx
# (Kamal's default health check path), and config/environments/production.rb
# already exempts /up from host authorization and request logging.
class HealthCheckTest < ActionDispatch::IntegrationTest
  test "GET /up answers 200 without authentication" do
    get "/up"

    assert_response :ok
  end
end
