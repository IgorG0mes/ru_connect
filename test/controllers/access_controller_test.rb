require "test_helper"

class AccessControllerTest < ActionDispatch::IntegrationTest
  test "should get Identification" do
    get access_Identification_url
    assert_response :success
  end
end
