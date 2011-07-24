require "test_helper"

class WorkLogsControllerTest < ActionController::TestCase
  fixtures(:projects)
  
  signed_in_admin_context do
    setup do
      project = projects(:test_project)
      @task = Task.make(:users => [ @user ], :project => project,
                        :company => @user.company)
      assert_not_nil @task
    end

    should "be able to render new work log form" do
      get :new, :task_id => @task.task_num
      assert_response :success
    end

    should "be able to create a new work log" do
      params = {
        :started_at => Time.now.strftime("#{ @user.date_format } #{ @user.time_format }"),
        :duration => "120m",
        :body => "test body"
      }

      put(:create, :task_id => @task.task_num, :work_log => params)

      log = assigns("log")
      assert_not_nil log
      assert_equal 7200, log.duration
      assert_equal "test body", log.body
      assert log.comment?

      assert_redirected_to '/tasks'
    end

    context "with an existing work log" do
      setup do
        @log = WorkLog.make(:task => @task, :company => @user.company, :project=>@user.projects.first)
      end

      should "render edit for the work log" do
        get :edit, :id => @log.id
        assert_response :success
      end

      should "be able to delete the work log" do
        delete :destroy, :id => @log.id
        assert_nil WorkLog.find_by_id(@log.id)
        assert_redirected_to '/tasks'
      end

      should "be able to update the work log" do
        new_time = Time.now.yesterday
        params = {
          :started_at => new_time.strftime("#{ @user.date_format } #{ @user.time_format }"),
          :duration => "120m",
          :body => "test body"
        }
        post(:update, :id => @log.id, :work_log => params)
        @log = WorkLog.find(@log.id)
        assert_equal 7200, @log.duration
        assert_equal "test body", @log.body
        assert @log.comment?

        assert_redirected_to '/tasks'
      end
    end
  end
end
