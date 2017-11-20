require 'test_helper'

class ShipmentsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get shipments_new_url
    assert_response :success
  end

end
