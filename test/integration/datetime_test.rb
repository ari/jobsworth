require 'test_helper'

class DatetimeTest < ActionController::IntegrationTest
  def self.shared_examples_for_user
    context "when edit task" do
        setup do
          @project = project_with_some_tasks(@user)
          @task =@project.tasks.first
          visit ('/tasks/edit/'+@task.task_num.to_s)
        end
        should "see local current time in field Start" do
          local_datetime = @user.tz.utc_to_local(Time.now.utc)
          start_datetime= find_by_id('work_log_started_at').value
          start_datetime= DateTime.strptime(start_datetime, @user.date_format + ' ' + @user.time_format).to_time
          assert_in_delta local_datetime, start_datetime, 2.minute
        end
        context "and add comment with 'Time spent'" do
          setup do
            fill_in "comment", :with => "my new comment"
            fill_in "work_log_duration", :with => "5m"
          end
          context "in task_history -> log_time" do
            should "see the same start time, as was in the field 'Start', when not change 'Start' time" do
              start_datetime= find_by_id('work_log_started_at').value.split(' ').second
              click_button "Save"
              start_log_time= find(:css, '.log_time').text.split('-').first.gsub(/\s/,'')
              assert_equal start_datetime, start_log_time
            end
            should "see the same start time, which was in the field 'Start', when change 'Start' time" do
              start_datetime= fill_in('work_log_started_at', :with =>"26/10/2010 11:50").split(' ').second
              click_button "Save"
              start_log_time= find(:css, '.log_time').text.split('-').first.gsub(/\s/,'')
              assert_equal start_datetime, start_log_time
            end
          end
          context "and click to /work_logs/edit link" do
            setup do
              @start_datetime= find_by_id('work_log_started_at').value
              click_button "Save"
              click_link('5m')
            end
            should "see in work_logs/edit 'Start' field the same time, as in tasks/edit 'Start' field" do
              start_datetime_log_edit= find_by_id('work_log_started_at').value
              assert_equal @start_datetime, start_datetime_log_edit
            end
            should "see in work_logs/edit 'Start' field the same time, as in tasks/edit log_time, when click save and follow to task edit" do
              start_datetime_log_edit= find_by_id('work_log_started_at').value.split(' ').second
              fill_in('work_log_body', :with => "new text")
              click_button "Save"
              start_log_time= find(:css, '.log_time').text.split('-').first.gsub(/\s/,'')
              assert_equal start_datetime_log_edit, start_log_time
            end
          end
        end
        context "with existed todo item" do
          setup do
            @task.todos.create!(:name=>"Todo #1", :creator_id=>@user.id)
            @todo= @task.todos.last
          end
          should "be local user time, when todo completed" do
            visit("/todos/toggle_done/#{@todo.id}?task_id=#{@task.id}")
            localtime= @user.tz.utc_to_local(Time.now.utc)
            todotime= find(:css, "#todos-#{@todo.id}").text.scan(/\[(.*)\]/).first.first
            todotime= DateTime.strptime(todotime, @user.date_format + ' ' + @user.time_format).to_time
            assert_in_delta localtime, todotime, 2.minute
          end
     end
     end
  end
  context "A logged in user" do 
    setup do 
      @user= login
      @user.option_tracktime=true
      @user.save!
    end  
    context "from Russia(utc+4)" do
      setup do
        @user.time_zone= "Europe/Moscow"
        @user.save!
      end
      shared_examples_for_user
    end
    context "from Uruguay(utc-3, summer utc-2)" do
       setup do
        @user.time_zone= "America/Montevideo"
        @user.save!
      end
      shared_examples_for_user
    end
  end
end
