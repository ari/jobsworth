require "test_helper"

class CustomAttributesControllerTest < ActionController::TestCase
  signed_in_admin_context do
    should "render :success on /index" do
      get :index
      assert_response :success
    end

    should "render :success on /edit" do
      get :index, :type => "User"
      assert_response :success
    end
  end
end
