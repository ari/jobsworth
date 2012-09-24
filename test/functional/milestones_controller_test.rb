require 'test_helper'

class MilestonesControllerTest < ActionController::TestCase
  fixtures :customers
  def setup
    @request.with_subdomain('cit')
    @user = User.make(:admin)
    sign_in @user
    @request.session[:user_id] = @user.id
    @user.company.create_default_statuses
    3.times {
      project = Project.make(:customer => @user.customer, :company => @user.company)
      project.users << @user
    }
  end

  context 'a normal milestone' do
    should "render get_milestones" do
      @task = Task.make(:company => @user.company, :project => @user.projects.first)
      get :get_milestones, :project_id => @task.project.id
      assert_response :success
    end

    should "get_milestones not include locked milestone" do
      @project = @user.projects.first
      @project.milestones.delete_all
      3.times { Milestone.make(:project => @project, :company => @user.company) }
      locked_milestone = Milestone.create(:project => @project, :status_name => :locked, :company => @user.company)
      get :get_milestones, :project_id => @project.id

      assert_equal 3, assigns(:milestones).size
      assert !assigns(:milestones).include?(locked_milestone)
    end

    should "get_milestones not include closed milestone" do
      @project = @user.projects.first
      @project.milestones.delete_all
      5.times { Milestone.make(:project => @project, :company => @user.company) }
      closed_milestone = Milestone.create(:project => @project, :status_name => :closed, :company => @user.company)
      get :get_milestones, :project_id => @project.id
      assert_equal 5, assigns(:milestones).size
      assert !assigns(:milestones).include?(closed_milestone)
    end

    should "be able to create milestone" do
      get :new, :project_id => @user.projects.first.id
      assert_response :success

      post :create, :milestone => {:name => "test", :due_at => Time.now.ago(-3.days), :description => "test milestone", :project_id => Project.first.id}
      assert_response 302
    end

    should "be able to update milestone" do
      project = @user.projects.first
      milestone = project.milestones.create!(:name => "test", :due_at => Time.now.ago(-3.days), :description => "test milestone", :company => @user.company)

      get :edit, :id => milestone.id
      assert_response :success

      put :update, :id => milestone.id, :milestone => {:name => "test2"}
      assert_response 302
    end

    should "be able to destroy milestone" do
      project = @user.projects.first
      milestone = project.milestones.create!(:name => "test", :due_at => Time.now.ago(-3.days), :description => "test milestone", :company => @user.company)

      delete :destroy, :id => milestone.id
      assert_redirected_to edit_project_path(project)
    end

    should "be able to complete milestone" do
      project = @user.projects.first
      milestone = project.milestones.create!(:name => "test", :due_at => Time.now.ago(-3.days), :description => "test milestone", :company => @user.company)

      assert !milestone.closed?
      post :complete, :id => milestone.id
      assert milestone.reload.closed?
    end

    should "be able to revert milestone" do
      project = @user.projects.first
      milestone = project.milestones.create!(:name => "test", :due_at => Time.now.ago(-3.days), :description => "test milestone", :company => @user.company, :completed_at => Time.now, :status_name => :closed)

      assert milestone.closed?
      post :revert, :id => milestone.id
      assert !milestone.reload.closed?
    end
  end
end
