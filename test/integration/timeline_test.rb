require 'test_helper'

class TimelineTest < ActionController::IntegrationTest
  context "with using envjs a logged in user" do
    setup do
      Capybara.javascript_driver= :envjs
      @user = login
      @user.option_tracktime=true
      @user.save!
    end

    context "with some existing task and worklog" do
      setup do
        @project = project_with_some_tasks(@user)
        @task = @project.tasks.first
        @task.name= "<script>alert('Title!!!');</script>"
        @task.save!
        wl= WorkLog.new
        wl.task= @task
        wl.user= @user
        wl.project= @project
        wl.company= @task.company
        wl.started_at= @user.tz.utc_to_local(Time.now)
        wl.duration= "5m"
        wl.body = "<script>alert('Body!!!');</script>"
        wl.save!

        el = wl.create_event_log(
          :company     =>   wl.company,
          :user        =>   wl.user,
          :project     =>   wl.project,
          :event_type  =>   EventLog::TASK_COMMENT
        )

        @log = @task.reload.work_logs.detect { |wl| wl.body == "<script>alert('Body!!!');</script>" }
        assert_not_nil @log, "log"
        visit "/timeline/list"
      end

      should "see unescaped worklog body on timeline/list page" do
        assert page.has_content?('Timeline'), "visit timeline/list"
        assert page.has_content?("<script>alert('Body!!!');</script>"), "log body"
      end

      should "see unescaped task title on timeline/list page" do
        assert page.has_content?("<script>alert('Title!!!');</script>"), "task title"
      end
    end
  end
end
