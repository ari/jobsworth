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

  specify "/list should render :success" do
    company = companies("cit")

    # need to create a task to ensure the task partials get rendered
    task = Task.new(:name => "Test", :project_id => company.projects.last.id)
    task.company = company
    task.save!

    get :list
    status.should.be :success

    # ensure at least 1 task was rendered
    group = assigns["groups"].first
    assert group.length > 0
  end

end
