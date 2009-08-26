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
      Status.create_default_statuses(@user.company)
      status = @user.company.statuses.rand
      get :search, :filter => status.name
      assert_tag(:attributes => { 
                   :class => "id", 
                   :value => status.id
                 })
    end

    should "be able to search by task user" do
      get :search, :filter => @user.name
      assert_tag(:attributes => { 
                   :class => "id", 
                   :value => @user.id
                 })
    end

    should "be able to search by keyword" do
      get :search, :filter => "A keyword"
      assert_tag(:attributes => { 
                   :class => "id", 
                   :value => "a keyword"
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

    context "when saving their current filter" do
      setup do
        filter = TaskFilter.system_filter(@user)
        filter.qualifiers.build(:qualifiable => @task.project)
        filter.keywords.build(:task_filter => filter, :company => @user.company, 
                              :word => "keyword")
        filter.save!
        
        post(:create, :task_filter => { :name => "a new filter" })
        @filter = TaskFilter.first(:conditions => { :user_id => @user.id, 
                                     :name => "a new filter" })
      end

      should "redirect to task list" do
        assert_redirected_to "/tasks/list"
      end

      should "save to the db" do
        assert !@filter.new_record?
        assert_equal "a new filter", @filter.name
        assert_equal @user, @filter.user
        assert_equal @user.company, @filter.user.company
      end

      should "save qualifiers" do
        assert_equal 1, @filter.qualifiers.length
        assert_equal @task.project, @filter.qualifiers[0].qualifiable
      end

      should "save keywords" do
        assert_equal 1, @filter.keywords.length
        assert_equal "keyword", @filter.keywords[0].word
      end
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
        system_filter = TaskFilter.system_filter(@user)

        assert_equal @filter.qualifiers.length, system_filter.qualifiers.length
        assert_equal @filter.keywords.length, system_filter.keywords.length
      end

      should "be able to delete their own filter" do
        delete :destroy, :id => @filter.id
        assert_redirected_to "/tasks/list"
        assert_nil TaskFilter.find_by_id(@filter.id)
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
          system_filter = TaskFilter.system_filter(@user)
          assert_equal @filter.qualifiers.length, system_filter.qualifiers.length
          assert_equal @filter.keywords.length, system_filter.keywords.length
        end

        should "be able to delete another user's shared filter if they are admin" do
          @filter.update_attribute(:shared, true)

          assert @user.admin?
          delete :destroy, :id => @filter.id
          assert_redirected_to "/tasks/list"
          assert_nil TaskFilter.find_by_id(@filter.id)
        end

        should "not be able to delete another user's shared filter if they are not an admin" do
          @filter.update_attribute(:shared, true)

          @user.update_attribute(:admin, false)
          assert !@user.admin?
          delete :destroy, :id => @filter.id
          assert_redirected_to "/tasks/list"
          assert_not_nil TaskFilter.find_by_id(@filter.id)
        end
      end
    end

    should "be able to set a single session value" do
      post :set_single_task_filter, :name => "sort", :value => "client down"
      assert_equal "client down", @response.session[:filter_sort]
    end
  end 
end
