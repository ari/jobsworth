require File.dirname(__FILE__) + '/../test_helper'

context "Tasks" do
  fixtures :users, :companies, :tasks
  
  setup do
    use_controller TasksController

    @request.with_subdomain('cit')
    @request.session[:user_id] = users(:admin).id
  end
  
  specify "/edit should render :success" do
    task = tasks(:normal_task)

    get :edit, :id => task
    status.should.be :success
  end

end
