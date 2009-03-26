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

  specify "/new should render :success" do
    get :new
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

  specify "/list should works with tags" do
    company = companies("cit")
    user = company.users.first
    @request.session[:filter_user] = [ user.id.to_s ]

    # need to create a task to ensure the task partials get rendered
    task = Task.new(:name => "Test", :project_id => company.projects.last.id)
    task.company = company
    task.set_tags = "tag1"
    task.task_owners.build(:user => user)
    task.save!

    get :list, :tag => "tag1"
    status.should.be :success

    # ensure at least 1 task was rendered
    group = assigns["groups"].first
    assert group.length > 0
  end
end
