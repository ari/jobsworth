require File.dirname(__FILE__) + '/../test_helper'


class ScheduleControllerTest < ActionController::TestCase
  fixtures :users, :companies, :tasks
  
  def setup
    @request.with_subdomain("cit")
    @request.session[:user_id] = users(:admin).id
  end

  test "/gantt should display and assign some tasks" do
    get :gantt
    assert_response :success

    tasks = assigns['tasks']
    assert_not_nil tasks
    assert tasks.length > 0
  end 

  test "/list should display and assign some tasks" do
    get :list
    assert_response :success

    tasks = assigns['tasks']
    assert_not_nil tasks
#    assert tasks.length > 0
  end 
end
