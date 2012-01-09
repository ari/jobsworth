require 'test_helper'

class DatetimeTest < ActionController::IntegrationTest
  def self.shared_examples_for_user
    context "when edit task" do
        setup do
          @project = project_with_some_tasks(@user)
          @task =@project.tasks.first
          visit ('/tasks/edit/'+@task.task_num.to_s)
          @local_datetime = Time.now
        end

        context "and add comment with 'Time worked'" do
          setup do
            fill_in "comment", :with => "my new comment"
            fill_in "work_log_duration", :with => "5m"
          end
          context "in task_history -> log_time" do
            should "see the current time, when not change 'Start' time" do
              click_button "Save"
              start_log_time = @task.work_logs.last.started_at
              assert_in_delta @local_datetime, start_log_time, 2.minute
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
            assert_in_delta @local_datetime, @todo.reload.completed_at, 2.minute
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
