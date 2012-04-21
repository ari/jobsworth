require "test_helper"

class ApplicationControllerTest < ActionController::TestCase
  tests ActivitiesController

  fixtures :users, :companies, :customers, :tasks, :projects, :milestones, :work_logs

  signed_in_admin_context do

  should "get current_user" do
     get :index
     assert_equal users(:admin), @controller.current_user
  end

  should "user 1 be an admin" do
     get :index
     assert assigns(:current_user).admin?
  end

  should "user 2 NOT to be an admin" do
    user = users(:fudge)
    user.company.create_default_statuses
    sign_in user
    @request.session[:user_id] = user.id
    get :index
    assert !assigns(:current_user).admin?
  end

  should "parse_time to handle 1w2d3h4m" do
     get :index
     assert_equal 200040, @controller.parse_time("1w2d3h4m")
     assert_equal 240, @controller.parse_time("4m")
     assert_equal 27000, @controller.parse_time("1d")
  end

  should "clients menu item to be showed for non admin users with read client option" do
    user = users(:admin)
    user.update_attributes(:read_clients => true)
    user.admin=false
    user.save!
    get :index
    assert_response :success
  end

  should "clients menu item to be not showed for non admin users without read client option" do
    user = users(:admin)
    user.update_attributes(:read_clients => false)
    user.admin=false
    user.save!
    get :index
    assert_response :success
  end

  should "never redirect back to url with ?format=js" do
    session[:history] = [ "/tasks?format=js" ]
    get :redirect_from_last
    assert_redirected_to root_url
  end

end
end
