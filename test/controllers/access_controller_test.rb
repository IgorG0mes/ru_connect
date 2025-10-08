require "test_helper"

class AccessControllerTest < ActionDispatch::IntegrationTest
  test "should get identification" do
    get identify_url
    assert_response :success
  end
end
