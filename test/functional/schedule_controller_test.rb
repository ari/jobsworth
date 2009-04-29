require File.dirname(__FILE__) + '/../test_helper'


class ScheduleControllerText < ActionController::TestCase
  fixtures :users, :companies, :tasks
  
  def setup
    use_controller ScheduleController
    @request.with_subdomain("cit")
    @request.session[:user_id] = users(:admin).id
  end

  test "/gantt should display and assign some tasks" do
    get :gantt
    status.should_be :success

    tasks = assigns['tasks']
    assert_not_nil tasks
    assert tasks.length > 0
  end 

  test "/list should display and assign some tasks" do
    get :list
    status.should_be :success

    tasks = assigns['tasks']
    assert_not_nil tasks
    assert tasks.length > 0
  end 
end
