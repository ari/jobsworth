require File.dirname(__FILE__) + '/../test_helper'
require 'notifications'


class NotificationsTest < ActiveRecord::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"
  fixtures :users, :tasks, :projects, :customers, :companies

  context "a normal notification" do
    setup do
      # need to hard code these configs because the fixtured have hard coded values
      $CONFIG[:domain] = "clockingit.com"
      $CONFIG[:email_domain] = $CONFIG[:domain].gsub(/:\d+/, '')

      @expected = TMail::Mail.new
      @expected.set_content_type "text", "plain", { "charset" => CHARSET }

      @expected.from     = "#{$CONFIG[:from]}@#{$CONFIG[:email_domain]}"
      @expected.reply_to = 'task-1@cit.clockingit.com'
      @expected.to       = 'admin@clockingit.com'
      @expected['Mime-Version'] = '1.0'
      @expected.date     = Time.now
    end

    context "with a user with access to the task" do
      setup do
        @task = tasks(:normal_task)
        @user = users(:admin)
      end

      should "create created mail as expected" do
        @expected.subject  = '[ClockingIT] Created: [#1] Test [Test Project] (Unassigned)'
        @expected.body     = read_fixture('created')

        notification = Notifications.create_created(@task, @user, 
                                                    @task.notification_email_addresses(@user), 
                                                    "", @expected.date)
        assert_equal @expected.encoded.strip, notification.encoded.strip
      end

      should "create changed mail as expected" do
        @expected.subject = '[ClockingIT] Resolved: [#1] Test -> Open [Test Project] (Erlend Simonsen)'
        @expected['Mime-Version'] = '1.0'
        @expected.body    = read_fixture('changed')
        
        notification = Notifications.create_changed(:completed, @task, @user,
                                                    @task.notification_email_addresses(@user),
                                                    "Task Changed", @expected.date)
        assert_equal @expected.encoded.strip, notification.encoded.strip
        assert_not_nil @expected.body.index("/tasks/view/")
      end
    end

    context "a user without access to the task" do
      setup do
        @task = tasks(:normal_task)
        @user = users(:tester)
        @user.project_permissions.destroy_all
        assert !@task.project.users.include?(@user)
      end

      should "create changed mail without view task link" do
        notification = Notifications.create_changed(:completed, @task, @user,
                                                    @task.notification_email_addresses(@user),
                                                    "Task Changed", @expected.date)
        assert_nil notification.body.index("/tasks/view/")
      end      

      should "create created mail without view task link" do
        notification = Notifications.create_created(@task, @user, 
                                                    @task.notification_email_addresses(@user), 
                                                    "", @expected.date)
        assert_nil notification.body.index("/tasks/view/")
      end      
    end
  end

  private
  def read_fixture(action)
    File.open("#{FIXTURES_PATH}/notifications/#{action}").read
  end

  def encode(subject)
    quoted_printable(subject, CHARSET)
  end
end

