require "test_helper"

class ErrorsControllerTest < ActionController::TestCase
  tests ErrorsController

  test "not_found responds with 404 JSON when content-type is JSON" do
    @request.headers["Content-Type"] = "application/json"
    get :not_found

    assert_response :not_found
    body = JSON.parse(response.body)
    assert_equal 404, body["code"]
    assert_equal "Not found.", body["error_message"]
  end

  test "not_found responds with 404 HTML when content-type is not JSON" do
    get :not_found

    assert_response :not_found
    assert_match(/text\/html/, response.media_type)
  end

  test "internal_server_error responds with 500 JSON when content-type is JSON" do
    @request.headers["Content-Type"] = "application/json"
    get :internal_server_error

    assert_response :internal_server_error
    body = JSON.parse(response.body)
    assert_equal 500, body["code"]
    assert_equal "Internal server error.", body["error_message"]
  end

  test "internal_server_error responds with 500 HTML when content-type is not JSON" do
    get :internal_server_error

    assert_response :internal_server_error
    assert_match(/text\/html/, response.media_type)
  end
end
