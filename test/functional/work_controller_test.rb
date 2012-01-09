require 'test_helper'

class WorkControllerTest < ActionController::TestCase
  signed_in_admin_context do
    setup do
      project = project_with_some_tasks(@user)
      @task = project.tasks.first
      assert @user.can_view_task?(@task)
    end

    should "render start" do
      get :start, :task_num => @task.task_num

      sheet = assigns("current_sheet")
      assert_equal @task, sheet.task
      assert_equal @user, sheet.user
      assert_redirected_to root_url
      sheet.destroy
    end

    context "with a current sheet" do
      setup do
        @sheet = Sheet.new(:user => @user, :task => @task,
                           :project => @task.project)
        @sheet.created_at = 30.minutes.ago
        @sheet.save!
      end

      should "render stop" do
        get :stop
        assert @user.sheets(true).empty?
        redir = @response.redirect_url
        assert redir.index("/work_logs/new?")
      end

      should "render cancel" do
        get :cancel
        assert_redirected_to root_url
        assert @user.sheets(true).empty?
      end

      should "toggle sheet paused on pause" do
        get :pause
        sheet = assigns("current_sheet")
        assert sheet.paused?

        get :pause
        assert !sheet.paused?
      end
    end
  end
end
