require 'test_helper'

class FilterControllerTest < ActionController::TestCase
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
      get :index
      assert_equal "<ul></ul>", @response.body.gsub("\n", "")
    end

    should "be able to search by task project" do
      get :index, :filter => @task.project.name
      assert_tag(:attributes => { 
                   :class => "id", 
                   :name => "filter[]", 
                   :value => "p#{ @task.project.id }" })
    end

    should "be able to search by task customer" do
      get :index, :filter => @task.project.customer.name
      assert_tag(:attributes => { 
                   :class => "id", 
                   :name => "filter[]",
                   :value => "c#{ @task.project.customer.id }" })
    end


    should "be able to search by task milestone" do
      get :index, :filter => @task.milestone.name
      assert_tag(:attributes => { 
                   :class => "id", 
                   :name => "filter[]",
                   :value => "m#{ @task.milestone.id }" })
    end

    should "be able to search by task status" do
      get :index, :filter => "Closed"
      assert_tag(:attributes => { 
                   :class => "id", 
                   :name => "filter_status[]",
                   :value => "2"
                 })
    end

    should "be able to search by task attributes" do
      property = @user.company.properties.first
      value = property.property_values.first
      assert_not_nil property
      assert_not_nil value

      get :index, :filter => value.value
      assert_tag(:attributes => { 
                   :class => "id", 
                   :name => "#{ property.filter_name }[]",
                   :value => value.id
                 })
    end

    should "be able to search by task user" do
      get :index, :filter => @user.name
      assert_tag(:attributes => { 
                   :class => "id", 
                   :name => "filter_user[]",
                   :value => @user.id
                 })
    end

    should "be able to set a single session value" do
      post :set_single_task_filter, :name => "sort", :value => "client down"
      assert_equal "client down", @response.session[:filter_sort]
    end
  end 
end
