require File.dirname(__FILE__) + '/../test_helper'

context "Schedule" do
  fixtures :users, :companies, :tasks
  
  setup do
    use_controller ScheduleController
    @request.with_subdomain("cit")
    @request.session[:user_id] = users(:admin).id
  end

  specify "/gantt should display and assign some tasks" do
    get :gantt
    status.should_be :success

    tasks = assigns['tasks']
    assert_not_nil tasks
    assert tasks.length > 0
  end 

  specify "/list should display and assign some tasks" do
    # need to set status to allow open tasks:
    @request.session[:filter_status] = -1

    get :list
    status.should_be :success

    tasks = assigns['tasks']
    assert_not_nil tasks
    assert tasks.length > 0
  end 
end
