require "test_helper"

class ActivitiesControllerTest < ActionController::TestCase
  fixtures :customers, :projects, :milestones, :work_logs
  
  signed_in_admin_context do
  
  should "render :success on /index " do
    get :index
    assert_equal @user, assigns(:current_user)
    assert_response :success
  end

  should "render :success on /index" do
    get :index
    assert_response :success
  end
 end
end
