require 'test_helper'

class TaskEditTest < ActionController::IntegrationTest
  def self.make_test_for_due_date
    return true
    should "not change due_at if user not chenge it" do
      old_due=field_with_id("due_at").value
      fill_in "task_description", :with => 'changed description'
      click_button "save"
      visit "/tasks/edit/#{@task.task_num}"
      assert_equal field_with_id("due_at").value, old_due
      assert_equal 'changed description', @task.reload.description
    end
    should "change due_at " do
      fill_in "due_at", :with => "27/07/2009"
      click_button "save"
      visit "/tasks/edit/#{@task.task_num}"
      assert_equal field_with_id("due_at").value,  "27/07/2009"
    end
  end
  context "A logged in user" do
    setup do
      @user = login
    end

    context "with some existing tasks" do
      setup do
        @project = project_with_some_tasks(@user)
        @project2 = project_with_some_tasks(@user)

        2.times { @project.milestones.make(:project => @project, :user => @user,
                                 :company => @project.company) }
      end

      context "on the task edit screen" do
        setup do
          @task = @project.tasks.first
          @task.due_at = Time.now + 3.days
          @task.save!
          visit "/tasks/edit/#{@task.task_num}"
        end

        should "be able to edit information" do
          fill_in "task_name", :with => "a new title"
          fill_in "tags", :with => "t1, t2"
          fill_in "task_description", :with => "a new description"

          click_button "save"

          @task.reload
          assert_equal "a new title", @task.name
          assert_equal "a new description", @task.description
          assert_equal "T1 / T2", @task.full_tags_without_links
        end

        should "be able to set a project" do
          assert_equal @project, @task.project
          select @project2.name, :from => "project"
          click_button "save"
          assert_equal @project2, @task.reload.project
        end

        should "be able to set a milestone" do
          assert_nil @task.milestone
          select @project.milestones.last.name, :from => "milestone"
          click_button "save"
          assert_equal @project.milestones.last, @task.reload.milestone
        end

        should "be able to set the status" do
          select "Closed", :from => "task_status"
          click_button "save"
          assert_equal "Closed", @task.reload.status_type
        end

        should "be able to add comments" do
          assert @task.work_logs.empty?
          fill_in "comment", :with => "a new comment"
          click_button "save"
          assert_not_nil @task.reload.work_logs.first.body.index("a new comment")
        end

        should "be able to set the time estimate" do
          fill_in "task_duration", :with => "4h"
          click_button "save"
          assert_equal 240, @task.reload.duration
        end

        context "be able to set the due date" do
          context "a logged in user from GMT -8 time zone" do
            setup do
              @user.time_zone='America/Chicago'
              @user.save!
            end
            make_test_for_due_date
          end
          context "a logged in user from GMT +2 time zone" do
            setup do
              @user.time_zone="Europe/Kiev"
              @user.save!
            end
            make_test_for_due_date
          end
        end

        should "be able to set type" do
          prop = property_named("type")
          select "Defect", :from => "type"
          click_button "save"
          assert_equal "Defect", @task.reload.property_value(prop).value
        end

        should "be able to set priority" do
          prop = property_named("priority")
          select "Critical", :from => "priority"
          click_button "save"
          assert_equal "Critical", @task.reload.property_value(prop).value
        end

        should "be able to set severity" do
          prop = property_named("severity")
          select "Trivial", :from => "severity"
          click_button "save"
          assert_equal "Trivial", @task.reload.property_value(prop).value
        end

        should "be able to create a worklog" do
          date = "15/06/2009 13:15"
          format = "#{ @user.date_format } #{ @user.time_format }"
          expected_date = DateTime.strptime(date, format)
          expected_date = @user.tz.local_to_utc(expected_date)

          fill_in "work_log_started_at", :with => date
          fill_in "work_log_duration", :with => "5m"
          fill_in "comment", :with => "some work log notes"
          click_button "save"

          log = @task.reload.work_logs.detect { |wl| wl.duration == 300 }
          assert_not_nil log
          assert_equal 300, log.duration
          assert_equal expected_date, log.started_at
          assert_equal "some work log notes", log.body
        end

      end
    end
  end

  def property_named(name)
    name = name.downcase
    @user.company.properties.detect { |p| p.name.downcase == name }
  end


end
