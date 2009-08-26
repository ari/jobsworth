require File.dirname(__FILE__) + '/../test_helper'

class TasksControllerTest < ActionController::TestCase
  fixtures :users, :companies, :tasks, :customers, :projects
  
  def setup
    @request.with_subdomain('cit')
    @user = users(:admin)
    @request.session[:user_id] = @user.id
    @user.company.create_default_statuses
  end
  
  test "/edit should render :success" do
    task = tasks(:normal_task)

    get :edit, :id => task.task_num
    assert_response :success
  end

  test "/edit should find task by task num" do
    task = tasks(:normal_task)
    task.update_attribute(:task_num, task.task_num - 1)

    get :edit, :id => task.task_num
    assert_equal task, assigns["task"]

    get :edit, :id => task.id
    assert_not_equal task, assigns["task"]
  end

  test "/new should render :success" do
    get :new
    assert_response :success
  end

  test "/list_old should render :success" do
    company = companies("cit")

    # need to create a task to ensure the task partials get rendered
    task = Task.new(:name => "Test", :project_id => company.projects.last.id)
    task.company = company
    task.save!

    get :list_old
    assert_response :success

    # ensure at least 1 task was rendered
    group = assigns["groups"].first
    assert group.length > 0
  end

  test "/list_old should works with tags" do
    company = companies("cit")
    user = company.users.first
    @request.session[:filter_user] = [ user.id.to_s ]

    # need to create a task to ensure the task partials get rendered
    task = Task.new(:name => "Test", :project_id => company.projects.last.id)
    task.company = company
    task.set_tags = "tag1"
    task.task_owners.build(:user => user)
    task.save!

    get :list_old, :tag => "tag1"
    assert_response :success

    # ensure at least 1 task was rendered
    group = assigns["groups"].first
    assert group.length > 0
  end

  test "/list should render :success" do
    company = companies("cit")

    # need to create a task to ensure the task partials get rendered
    task = Task.new(:name => "Test", :project_id => company.projects.last.id)
    task.company = company
    task.save!

    get :list
    assert_response :success

    assert assigns["tasks"].include?(task)
  end

  test "/update should render form ok when failing update" do
    task = Task.first
    # post something that will cause a validation to fail
    post(:update, :id => task.id, :task => { :name => "" })

    assert_template "tasks/edit"
    assert_response :success
  end

  context "a task with a few users attached" do
    setup do
      ActionMailer::Base.deliveries = []
      @task = Task.first
      @task.users << @task.company.users
      @task.save!
      assert_emails 0
      @notify = @task.users.map { |u| u.id }
    end

    should "send emails to each user when adding a comment" do
      post(:update, :id => @task.id, :task => { },
           :notify => @notify, 
           :comment => "a test comment")
      assert_emails @task.users.length
      assert_redirected_to "/activities/list"
    end
  end

  context "a new task with a few users attached" do
    setup do
      ActionMailer::Base.deliveries = []
      assert_emails 0
      @user_ids = @user.company.users.map { |u| u.id }
    end

    should "send emails to each user when creating" do
      post(:create, :users => @user_ids, :assigned => @user_ids,
           :notify => @user_ids, 
           :task => { 
             :name => "test", 
             :description => "",
             :project_id => @user.company.projects.last.id
           })

      new_task = assigns(:task)
      assert_emails new_task.users.length
      assert_redirected_to "/activities/list"
    end
  end

  should "render create ok" do
    task = Task.first
    customer = task.company.customers.last
    project = customer.projects.first
    
    post(:create, :id => task.id, :task => { 
           :project_id => project.id,
           :customer_attributes => { customer.id => "1" } })

    assert_response :success
  end

  test "/save_log should update work log" do
    task = Task.first
    log = WorkLog.new(:started_at => Time.now.utc, :task => task,
                      :duration => 60, :company => @user.company)
    log.save!


    new_time = Time.now.yesterday
    params = { 
      :started_at => new_time.strftime("#{ @user.date_format } #{ @user.time_format }"),
      :duration => "120m",
      :body => "test body"
    }
    post(:save_log, :id => log.id, :work_log => params)
    
    log = WorkLog.find(log.id)
#    assert_equal new_time.utc, log.started_at
    assert_equal 7200, log.duration
    assert_equal "test body", log.body
    assert log.comment?
  end

end
