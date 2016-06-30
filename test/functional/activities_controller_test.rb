require 'test_helper'

class ActivitiesControllerTest < ActionController::TestCase
  fixtures :customers

  signed_in_admin_context do

  should 'render :success on /index ' do
    get :index
    assert_equal @user, assigns(:current_user)
    assert_response :success
  end

  should 'render :success on /index' do
    get :index
    assert_response :success
  end
 end
end
