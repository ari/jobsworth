require 'test_helper'

class TaskFiltersControllerTest < ActionController::TestCase
  context "a logged in user" do
    setup do
      @request.with_subdomain('cit')
      @user = users(:admin)
      @request.session[:user_id] = @user.id

      project = @user.company.projects.first
      milestone = Milestone.make(:project => project, :company => @user.company)
      @task = Task.make(:users => [ @user ], :company => @user.company,
                        :project => project, :milestone => milestone)
      assert_not_nil @task
    end

    should "return nothing with an empty search" do
      get :search
      assert_equal "<ul></ul>", @response.body.gsub("\n", "")
    end

    should "be able to search by task project" do
      get :search, :filter => @task.project.name
      assert_tag(:attributes => { 
                   :class => "id", 
                   :value => @task.project.id })
    end

    should "be able to search by task customer" do
      get :search, :filter => @task.project.customer.name
      assert_tag(:attributes => { 
                   :class => "id", 
                   :value => @task.project.customer.id })
    end


    should "be able to search by task milestone" do
      get :search, :filter => @task.milestone.name
      assert_tag(:attributes => { 
                   :class => "id", 
                   :value => @task.milestone.id })
    end

    should "be able to search by tags" do
      tag = Tag.make(:company => @user.company)
      get :search, :filter => tag.name
      assert_tag(:attributes => { 
                   :class => "id", 
                   :value => tag.id })
    end

    should "be able to search by task status" do
      get :search, :filter => "Closed"
      assert_tag(:attributes => { 
                   :class => "id", 
                   :name => "filter_status[]",
                   :value => "2"
                 })
    end

    should "be able to search by task user" do
      get :search, :filter => @user.name
      assert_tag(:attributes => { 
                   :class => "id", 
                   :value => @user.id
                 })
    end

    should "be able to search by task attributes" do
      property = @user.company.properties.first
      value = property.property_values.first
      assert_not_nil property
      assert_not_nil value

      get :search, :filter => value.value
      assert_tag(:attributes => { 
                   :class => "id", 
                   :value => value.id
                 })
    end

    should "be able to render new" do
      get :new
      assert_response :success
    end

    should "be able to save the current filter" do
      filter = TaskFilter.new(:user => @user)
      filter.qualifiers.build(:qualifiable => @task.project)
      @request.session[:task_filter] = filter

      post(:create, :task_filter => { :name => "a new filter" })
      assert_redirected_to "/tasks/list"

      filter = session[:task_filter]
      assert !filter.new_record?
      assert_equal "a new filter", filter.name
      assert_equal @user, filter.user
      assert_equal @user.company, filter.user.company
      assert_equal 1, filter.qualifiers.length
      assert_equal @task.project, filter.qualifiers[0].qualifiable
    end

    context "with an existing saved filter" do
      setup do
        @filter = TaskFilter.new(:name => "a test filter", :user => @user)
        @filter.qualifiers.build(:qualifiable => @task.project)
        @filter.save!
      end

      should "be able to select their own filter" do
        get :select, :id => @filter.id
        assert_redirected_to "/tasks/list"
        assert_equal @filter, session[:task_filter]
      end

      context "which belongs to another user" do
        setup do
          user = (@user.company.users - [ @user ]).rand
          assert_not_nil user
          @filter.update_attribute(:user, user)
        end

        should "not be able to select another user's filter" do
          get :select, :id => @filter.id
          assert_redirected_to "/tasks/list"
          assert_not_equal @filter, session[:task_filter]
          assert flash[:notice].index("access")
        end

        should "be able to select another user's shared filter" do
          @filter.update_attribute(:shared, true)
          get :select, :id => @filter.id
          assert_redirected_to "/tasks/list"
          assert_equal @filter, session[:task_filter]
        end
      end
    end

    should "be able to set a single session value" do
      post :set_single_task_filter, :name => "sort", :value => "client down"
      assert_equal "client down", @response.session[:filter_sort]
    end
  end 
end
