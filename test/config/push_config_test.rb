require "test_helper"

class PushConfigTest < ActiveSupport::TestCase
  test "apns connects to the sandbox server only in the development environment" do
    config = ActionPushNative.config

    assert config.key?(:apple), "expected push.yml to configure the :apple platform"
    assert_equal Rails.env.development?, config.dig(:apple, :connect_to_development_server)
  end
end
