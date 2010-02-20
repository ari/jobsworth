require 'test_helper'

class MilestonesControllerTest < ActionController::TestCase
  fixtures :users, :companies, :tasks, :customers, :projects
  def setup
    @request.with_subdomain('cit')
    @user = users(:admin)
    @request.session[:user_id] = @user.id
    @user.company.create_default_statuses
  end
  context 'a normal milestone' do
    should "render get_milestones" do
      @task=Task.first
      get :get_milestones, :project_id => @task.project.id
      assert_response :success
    end
  end
end
