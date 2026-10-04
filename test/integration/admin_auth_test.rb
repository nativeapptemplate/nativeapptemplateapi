require "test_helper"

class AdminAuthTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = AdminUser.create!(name: "Admin", email: "admin@example.com", password: "password")
  end

  test "signs in and reaches madmin" do
    sign_in_admin

    assert_redirected_to madmin_root_path
    get madmin_root_path
    assert_response :success
  end

  test "rejects a wrong password" do
    sign_in_admin(password: "wrong")

    assert_response :success
    assert_equal "Invalid email or password", flash[:alert]
    get madmin_root_path
    assert_redirected_to "/"
  end

  test "a deleted admin's session no longer reaches madmin" do
    sign_in_admin
    @admin_user.destroy!

    get madmin_root_path

    assert_redirected_to "/"
    assert_nil session[:admin_user_id]
  end

  test "signing in starts a new session" do
    # The alert on this redirect is stored in the session, so a session exists
    # before signing in (the sign-in page alone writes none)
    get madmin_root_path
    session_id_before = session.id.to_s
    assert session_id_before.present?

    sign_in_admin

    assert_not_equal session_id_before, session.id.to_s
  end

  test "signing out clears the session" do
    sign_in_admin
    delete destroy_admin_session_path

    get madmin_root_path
    assert_redirected_to "/"
  end

  test "the sixth sign-in attempt from one IP within a minute is rate limited" do
    # 5 attempts per minute per IP are allowed (the limit in the controller)
    5.times { |i| sign_in_admin(email: "nobody#{i}@example.com", password: "wrong") }

    sign_in_admin

    assert_response :too_many_requests
    assert_nil session[:admin_user_id]
  end

  test "the sixth sign-in attempt for one email within a minute is rate limited" do
    5.times { |i| sign_in_admin(password: "wrong", ip: "10.0.0.#{i + 1}") }

    sign_in_admin(ip: "10.0.0.99")

    assert_response :too_many_requests
    assert_nil session[:admin_user_id]
  end

  private

  def sign_in_admin(email: @admin_user.email, password: "password", ip: nil)
    headers = ip ? {"REMOTE_ADDR" => ip} : {}
    post admin_session_path, params: {email: email, password: password}, headers: headers
  end
end
