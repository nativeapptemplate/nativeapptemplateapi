require "test_helper"

class ShopkeeperMailerTest < ActionMailer::TestCase
  test "inherits from ApplicationMailer" do
    assert_operator ShopkeeperMailer, :<, ApplicationMailer
  end

  test "uses the application default_from address" do
    assert_equal ConfigSettings.email.default_from_with_name, ShopkeeperMailer.default[:from]
  end

  test "uses the mailer layout" do
    assert_equal "mailer", ShopkeeperMailer._layout
  end
end
