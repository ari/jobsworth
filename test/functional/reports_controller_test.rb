require File.dirname(__FILE__) + '/../test_helper'

class ReportsControllerTest < ActionController::TestCase
  fixtures :users, :companies, :tasks, :customers
  
  def setup
    @request.with_subdomain('cit')
    @user = users(:admin)
    @request.session[:user_id] = @user.id
    @user.company.create_default_statuses
  end

  test "list should render" do
    get :list
    assert_response :success
  end

  test "pivot report should render" do
    assert_report_works(WorklogReport::PIVOT)
  end

  test "audit report should render" do
    assert_report_works(WorklogReport::AUDIT)
  end

  test "timesheet report should render" do
    assert_report_works(WorklogReport::TIMESHEET)
  end

  test "workload report should render" do
    assert_report_works(WorklogReport::WORKLOAD)
  end

  private

  def assert_report_works(type)
    t1 = Task.first
    t1.update_attributes(:duration => 1000)
    log = t1.work_logs.build(:started_at => Time.now, :duration => 60,
                             :company => @user.company, :user => @user,
                             :customer => @user.company.customers.first,
                             :project => t1.project)
    log.save!


    post :list, :report => {
      :type => type,
      :range => 0
    }
    assert_response :success
    assert_not_nil assigns["generated_report"]

    report = assigns["worklog_report"]
    worklogs = report.work_logs
    assert worklogs.any?
    if type != WorklogReport::WORKLOAD
      # workload report creates new placeholder logs, so created one
      # won't be included.
      assert worklogs.include?(log)
    end
  end
end
