require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  test "anonymous connection succeeds with nil shopkeeper and account" do
    connect

    assert_nil connection.current_shopkeeper
    assert_nil connection.current_account
  end

  test "authenticated connection identifies shopkeeper and account" do
    shopkeeper = shopkeepers(:one)
    account = shopkeeper.create_default_account
    warden = Minitest::Mock.new
    warden.expect(:user, shopkeeper, [:shopkeeper])

    connect "/#{account.id}/cable", env: {"warden" => warden}

    assert_equal shopkeeper, connection.current_shopkeeper
    assert_equal account, connection.current_account
    warden.verify
  end

  test "connection without account UUID in path has nil account" do
    shopkeeper = shopkeepers(:one)
    warden = Minitest::Mock.new
    warden.expect(:user, shopkeeper, [:shopkeeper])

    connect "/cable", env: {"warden" => warden}

    assert_equal shopkeeper, connection.current_shopkeeper
    assert_nil connection.current_account
    warden.verify
  end
end
