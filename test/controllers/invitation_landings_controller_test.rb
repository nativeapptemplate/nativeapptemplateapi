require "test_helper"

# Where the invitation mail's link lands when the app does not open it (not
# installed, or a browser that keeps the link)
class InvitationLandingsControllerTest < ActionDispatch::IntegrationTest
  teardown do
    ConfigSettings.mobile_app.app_store_url = ""
    ConfigSettings.mobile_app.play_store_url = ""
  end

  test "show asks to open the invitation in the app" do
    get "/invitations/123456"

    assert_response :success
    assert_equal "text/html", response.media_type
    assert_match I18n.t("invitation_landings.show.title", mobile_app: ConfigSettings.display_name), response.body
  end

  # The code is in the URL already; the page doesn't repeat it (it may be
  # opened on a shared screen) and doesn't look it up (anyone can open it)
  test "show does not show the code" do
    get "/invitations/123456"

    assert_no_match "123456", response.body
  end

  test "show links the stores that are set" do
    ConfigSettings.mobile_app.app_store_url = "https://apps.apple.com/app/example/id1"

    get "/invitations/123456"

    assert_select "a[href=?]", "https://apps.apple.com/app/example/id1"
    assert_no_match I18n.t("shopkeeper.notification_mailer.invited.android_app", mobile_app: ConfigSettings.display_name), response.body
  end

  test "show is in the browser's language" do
    get "/invitations/123456", headers: {"Accept-Language" => "ja"}

    assert_match I18n.t("invitation_landings.show.title", mobile_app: ConfigSettings.display_name, locale: :ja), response.body
  end
end
