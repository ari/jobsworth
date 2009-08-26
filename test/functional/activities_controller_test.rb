require File.dirname(__FILE__) + '/../test_helper'

class ActivitiesControllerTest < ActionController::TestCase
  fixtures :users, :companies, :customers, :tasks, :projects, :milestones, :work_logs
  
  def setup
    @request.with_subdomain('cit')
    @user = users(:admin)
    @request.session[:user_id] = @user.id
    @user.company.create_default_statuses
  end
  
  test "/index should render :success" do
    get :index
    assert_equal Timezone.get('Europe/Oslo'), assigns(:current_user).tz
    assert_equal users(:admin), assigns(:current_user)
    assert_response :success
  end

  test "/list should render :success" do
    get :list
    assert_response :success
  end
  
end
