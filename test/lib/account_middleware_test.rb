require "test_helper"

class AccountMiddlewareTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(name: "Team", owner: shopkeepers(:one), personal: false)
    @seen = {}
    app = ->(env) {
      @seen = {script_name: env["SCRIPT_NAME"], path_info: env["PATH_INFO"], account: Current.account}
      [200, {}, ["ok"]]
    }
    @middleware = AccountMiddleware.new(app)
  end

  teardown { Current.reset }

  test "an account id prefix selects the account and is moved into script_name" do
    status, = call("/#{@account.id}/api/v1/shopkeeper/shops")

    assert_equal 200, status
    assert_equal @account, @seen[:account]
    assert_equal "/#{@account.id}", @seen[:script_name]
    assert_equal "/api/v1/shopkeeper/shops", @seen[:path_info]
  end

  test "a bare account id becomes the root path" do
    call("/#{@account.id}")

    assert_equal "/#{@account.id}", @seen[:script_name]
    assert_equal "/", @seen[:path_info]
  end

  test "paths without an account id pass through untouched" do
    call("/api/v1/shopkeeper/shops")

    assert_nil @seen[:account]
    assert_equal "", @seen[:script_name]
    assert_equal "/api/v1/shopkeeper/shops", @seen[:path_info]
  end

  test "an unknown account id redirects to the root" do
    status, headers, = call("/00000000-0000-0000-0000-000000000000/api/v1/shopkeeper/shops")

    assert_equal 302, status
    assert_equal "/", headers["Location"]
    assert_empty @seen, "the app must not be called"
  end

  # Account ids are lowercase UUIDs, as Postgres' gen_random_uuid() returns them
  test "a segment that only looks like an id passes through" do
    call("/#{@account.id.upcase}/api")

    assert_nil @seen[:account]
    assert_equal "/#{@account.id.upcase}/api", @seen[:path_info]
  end

  private

  def call(path)
    @middleware.call(Rack::MockRequest.env_for(path))
  end
end
