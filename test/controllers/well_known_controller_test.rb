require "test_helper"

# The files that let the apps claim the invitation link (config/settings.yml
# app_links). The shapes are Apple's "Supporting associated domains" and
# Android's "Verify Android App Links" (Digital Asset Links) documents.
class WellKnownControllerTest < ActionDispatch::IntegrationTest
  teardown do
    ConfigSettings.app_links.ios_app_ids = []
    ConfigSettings.app_links.android_package = ""
    ConfigSettings.app_links.android_sha256_cert_fingerprints = []
  end

  test "apple-app-site-association claims the invitation path for the app IDs" do
    ConfigSettings.app_links.ios_app_ids = ["ABCDE12345.com.example.MyApp.ios"]

    get "/.well-known/apple-app-site-association"

    assert_response :success
    # Apple reads it without an extension, so the type must be set (not inferred)
    assert_equal "application/json", response.media_type
    assert_equal(
      {"applinks" => {"details" => [{
        "appIDs" => ["ABCDE12345.com.example.MyApp.ios"],
        "components" => [{"/" => "/invitations/*"}]
      }]}},
      response.parsed_body
    )
  end

  test "apple-app-site-association is not found while no app ID is set" do
    get "/.well-known/apple-app-site-association"

    assert_response :not_found
  end

  test "assetlinks.json lets the package with the fingerprints handle the links" do
    ConfigSettings.app_links.android_package = "com.example.myapp"
    ConfigSettings.app_links.android_sha256_cert_fingerprints = ["AA:BB", "CC:DD"]

    get "/.well-known/assetlinks.json"

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_equal(
      [{
        "relation" => ["delegate_permission/common.handle_all_urls"],
        "target" => {
          "namespace" => "android_app",
          "package_name" => "com.example.myapp",
          "sha256_cert_fingerprints" => ["AA:BB", "CC:DD"]
        }
      }],
      response.parsed_body
    )
  end

  test "assetlinks.json is not found while the package or fingerprints are blank" do
    ConfigSettings.app_links.android_package = "com.example.myapp"

    get "/.well-known/assetlinks.json"

    assert_response :not_found
  end
end
