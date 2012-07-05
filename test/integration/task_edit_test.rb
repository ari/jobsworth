require 'test_helper'

class TaskEditTest < ActionController::IntegrationTest
  def self.make_test_for_due_date
    should "not change due_at if user not change it" do
      old_due=find_by_id("due_at").value
      fill_in "task_description", :with => 'changed description'
      click_button "Save"
      visit "/tasks/edit/#{@task.task_num}"
      assert_equal find_by_id("due_at").value, old_due
      assert_equal 'changed description', @task.reload.description
    end
    should "change due_at " do
      fill_in "due_at", :with => "27/07/2009"
      click_button "Save"
      visit "/tasks/edit/#{@task.task_num}"
      assert_equal find_by_id("due_at").value,  "27/07/2009"
    end
  end
  context "A logged in user" do
    setup do
      @user = login
      @user.option_tracktime=true
      @user.save!
    end

    context "with some existing tasks" do
      setup do
        @project = project_with_some_tasks(@user)
        @project2 = project_with_some_tasks(@user)

        2.times { @project.milestones.make(:project => @project, :user => @user,
                                 :company => @project.company) }
      end

      context "with email from unkown" do
        setup do
          @task = @project.tasks.first
          @email = Sham.email
        end

        should "be able to attach email to user" do
          @task.email_addresses.create(:email => @email)
          visit "/tasks/edit/#{@task.task_num}"
          assert_not_nil find_link(@email)
          visit find_link(@email)[:href]

          user = User.make(:customer => @user.customer, :company => @user.company)
          hidden_field = find_by_id("email_attach_user_id")
          hidden_field.set(user.id)
          click_button('Save')

          visit "/tasks/edit/#{@task.task_num}"              
          assert_raise(Capybara::ElementNotFound) { find_link(@email) }
          assert_not_nil find_link(user.name)
        end

      end

      context "edit tasks created from email" do
        setup do
          @task = Task.new(:description => "test task", :company => @project.company, :project => @project)
          @task.save(:validate => false)
          visit "/tasks/edit/#{@task.task_num}"
        end

        should "be able to keep comment on error" do
          fill_in "comment", :with => "a new comment"
          click_button "Save"
          assert page.has_content?("Name can't be blank")
          assert page.has_content?("a new comment")
        end
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
          fill_in "Tags", :with => "t1, t2"
          fill_in "task_description", :with => "a new description"

          click_button "Save"

          @task.reload
          assert_equal "a new title", @task.name
          assert_equal "a new description", @task.description
          assert_equal "T1 / T2", @task.full_tags_without_links
        end

        should "be able to set a project" do
          assert_equal @project, @task.project
          select @project2.name, :from => "Project"
          click_button "Save"
          assert_equal @project2, @task.reload.project
        end

        should "be able to set a milestone" do
          assert_nil @task.milestone
          select @project.reload.milestones.last.name, :from => "Milestone"
          click_button "Save"
          assert_equal @project.milestones.last, @task.reload.milestone
        end

        should "be able to set the status" do
          select "Closed", :from => "task_status"
          click_button "Save"
          assert_equal "Closed", @task.reload.status_type
        end

        should "be able to add comments" do
          assert @task.work_logs.empty?
          fill_in "comment", :with => "a new comment"
          click_button "Save"
          log= find(:css, '.log_comment').text
          assert_not_nil @task.reload.work_logs.first.body.index("a new comment")
          assert_not_nil log.index('a new comment')
          assert_not_nil find(:css, ".alert.alert-success").text.index("Task was successfully updated")
          assert_equal "", find_by_id("comment").value

          log_recipients = find(:css, '.log_recipients').text
          assert_not_nil log_recipients.index('Sent to Eliseo Kautzer')
        end

        should "be able to set the time estimate" do
          fill_in "task_duration", :with => "4h"
          click_button "Save"
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
              @user.time_zone="Europe/Moscow"
              @user.save!
            end
            make_test_for_due_date
          end
        end

        should "be able to set type" do
          prop = property_named("type")
          select "Defect", :from => "Type"
          click_button "Save"
          assert_equal "Defect", @task.reload.property_value(prop).value
        end

        should "be able to set priority" do
          prop = property_named("priority")
          select "Critical", :from => "Priority"
          click_button "Save"
          assert_equal "Critical", @task.reload.property_value(prop).value
        end

        should "be able to set severity" do
          prop = property_named("severity")
          select "Trivial", :from => "Severity"
          click_button "Save"
          assert_equal "Trivial", @task.reload.property_value(prop).value
        end

        should "be able to create a worklog" do
          date = "15/06/2009 13:15"
          format = "#{ @user.date_format } #{ @user.time_format }"
          expected_date = DateTime.strptime(date, format).ago(@user.tz.current_period.utc_total_offset)

          find("#taskform #work_log_started_at").set(date)
          find("#taskform #work_log_duration").set("5m")
          fill_in "comment", :with => "some work log notes"
          click_button "Save"

          log = @task.reload.work_logs.detect { |wl| wl.duration == 300 }
          assert_not_nil log
          assert_equal 300, log.duration
          assert_equal expected_date, log.started_at
          assert_equal "some work log notes", log.body
        end

        context "when on update triggers exist: set due date and reassign task to user" do
          setup do
            Trigger.destroy_all
            Trigger.new(:company=> @user.company, :event_id => Trigger::Event::UPDATED, :actions => [Trigger::SetDueDate.new(:days=>4)]).save!
            Trigger.new(:company=> @user.company, :event_id => Trigger::Event::UPDATED, :actions => [Trigger::ReassignTask.new(:user=>User.last)]).save!
            fill_in "task[due_at]", :with=>"27/07/2011"
            @task.work_logs.destroy_all
            click_button "Save"
            @task.reload
          end

          should "should set tasks due date" do
            assert_in_delta @task.due_date, (Time.now.utc+4.days), 10.minutes
          end
          should "create work log, when trigger set due date " do
            assert_not_nil @task.work_logs.where("work_logs.body like 'This task was updated by trigger\n- Due: #{@task.due_at.strftime_localized("%A, %d %B %Y")}\n'").last
          end

          should "should reassign taks to user" do
            assert_equal [User.last], @task.owners
          end
          should "create worklog, when trigger reassign task to user" do
            assert_not_nil @task.work_logs.where("work_logs.body like 'This task was updated by trigger\n- Assignment: #{@task.owners_to_display}\n'").last
          end
        end
      end
    end
  end

  def property_named(name)
    name = name.downcase
    @user.company.properties.detect { |p| p.name.downcase == name }
  end


end
