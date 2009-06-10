require File.dirname(__FILE__) + '/../test_helper'

class ReportsControllerTest < ActionController::TestCase
  fixtures :users, :companies, :tasks
  
  def setup
    @request.with_subdomain('cit')
    @user = users(:admin)
    @request.session[:user_id] = @user.id
  end

  test "list should render" do
    get :list
    assert_response :success
  end

  test "post list should render and contain logs" do
    t1 = Task.first
    log = t1.work_logs.build(:started_at => Time.now)
    log.save!

    post :list, :report => {
      :type => ReportsController::TIMESHEET,
      :range => 0
    }
    assert_response :success
    worklogs = assigns["logs"]
    assert worklogs.include?(log)
  end
end
