require 'test_helper'

class RailwaysControllerTest < ActionController::TestCase
  test "should get pnr" do
    get :pnr
    assert_response :success
  end

end
