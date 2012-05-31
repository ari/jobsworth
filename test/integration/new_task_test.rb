require 'test_helper'

class NewTaskTest < ActionController::IntegrationTest
  context "A logged in user with existings projects" do
    setup do
      @user = login
      @user.option_tracktime=true
      @user.save!
      @project = project_with_some_tasks(@user)
      @milestone =  Milestone.make(:project => @project, 
                                   :user => @user,
                                   :company => @project.company)
    end

    context "creating a new task" do
      setup do
        visit "/"
        click_link "New Task"

        fill_in "task_name", :with => "a brand new task"
        fill_in "task_description", :with => "a new desc"
        select @project.name, :from => "Project"
        select @milestone.name, :from => "Milestone"
      end

      should "be able to create task ok" do
        project_count = @project.tasks.count
        milestone_count = @milestone.tasks.count

        click_button "Save"

        assert_equal project_count + 1, @project.tasks.count
        assert_equal milestone_count + 1, @milestone.tasks.count
      end

      should "be able to create a worklog using the task description" do
        fill_in "comment", :with => "urgent"
        click_button "Save"

        task = @user.company.tasks.last
        log = task.reload.work_logs.detect { |wl| wl.body == 'urgent' }
        assert_not_nil log
        log = task.work_logs.first
        assert_match task.description, log.body
      end
      context "when on create triggers exist: set due date and reassign task to user" do
        setup do
          Trigger.destroy_all
          Trigger.new(:company=> @user.company, :event_id => Trigger::Event::CREATED, :actions => [Trigger::SetDueDate.new(:days=>4)]).save!
          Trigger.new(:company=> @user.company, :event_id => Trigger::Event::CREATED, :actions => [Trigger::ReassignTask.new(:user=>User.last)]).save!
          fill_in "task[due_at]", :with=>"27/07/2011"
          click_button "Save"
          @task = Task.last
        end

        should "should set tasks due date" do
          assert_in_delta @task.due_date, (Time.now.utc+4.days), 10.minutes
        end
        should "create worklog, when trigger set due date" do
          assert_not_nil @task.work_logs.where("work_logs.body like 'This task was updated by trigger\n- Due: #{@task.due_at.strftime_localized("%A, %d %B %Y")}\n'").first
        end
        should "should reassign taks to user" do
          assert_equal [User.last], @task.owners
        end
        should "create worklog, when trigger reassign task to user" do
          assert_not_nil @task.work_logs.where("work_logs.body like 'This task was updated by trigger\n- Assignment: #{@task.owners_to_display}\n'").first
        end
      end
    end
  end
end
