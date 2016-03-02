require "test_helper"

class BillingControllerTest < ActionController::TestCase
  setup do
    @user = User.make(:admin)
    sign_in @user
    @user.company.create_default_statuses
    project_with_some_tasks(@user)
  end

  should "render index" do
    get :index
    assert_response :success
  end

  should "render pivot report" do
    assert_report_works(WorklogReport::PIVOT)
  end

  should "render timesheet report" do
    assert_report_works(WorklogReport::TIMESHEET)
  end

  should "render pivot with custom dates" do
    start_date = Date.yesterday.strftime(@user.date_format)
    end_date = Date.tomorrow.strftime(@user.date_format)

    assert_report_works(WorklogReport::PIVOT,
                        :range => 7,
                        :start_date => start_date,
                        :end_date => end_date)
  end

  private

  def assert_report_works(type, params = {})
    t1 = @user.tasks.first
    t1.update_attributes(:duration => 1000)
    log = t1.work_logs.build(:started_at => Time.now, :duration => 60,
                             :company => @user.company, :user => @user,
                             :customer => @user.company.customers.first,
                             :project => t1.project)
    log.save!


    params[:range] ||= 0
    params[:type] = type
    post :index, :report => params
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
