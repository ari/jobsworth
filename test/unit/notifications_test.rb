require "test_helper"
require 'notifications'


class NotificationsTest < ActiveRecord::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "UTF-8"
  fixtures :users, :tasks, :projects, :customers, :companies

  context "a normal notification" do
    setup do
      # need to hard code these configs because the fixtured have hard coded values
      $CONFIG[:domain] = "clockingit.com"
      $CONFIG[:email_domain] = $CONFIG[:domain].gsub(/:\d+/, '')
      $CONFIG[:productName] = "Jobsworth"

      @expected = Mail.new
      @expected.set_content_type "text/plain; charset=#{CHARSET}"

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
        @user.projects<<@task.project
        @user.save!
        @work_log = WorkLog.make(:user => @user, :task => @task)
        @deliveries = []
        @task.users_to_notify(@user).each do |recipient|
          @deliveries << @work_log.email_deliveries.make(:email => recipient.email, :user=>recipient)
        end
      end

      should "create created mail as expected" do
        @expected.subject  = '[Jobsworth] Created: [#1] Test [Test Project] (Unassigned)'
        @expected.body     = read_fixture('created')
        @task.company.properties.destroy_all
        @task.company.create_default_properties
        @task.company.properties.each{ |p|
          @task.set_property_value(p, p.default_value)
        }
        notification = Notifications.created(@deliveries.first)
        assert_equal @task.users_to_notify(@user).map(&:email), [@user.email]
        assert @user.can_view_task?(@task)
        assert_match /tasks\/view/, notification.body.to_s
        assert_equal @expected.body.to_s, notification.body.to_s

        # check Message-ID
        assert notification.to_s =~ /Message\-ID:\s+<#{@deliveries.first.work_log.task.task_num}.#{@deliveries.first.work_log.id}.jobsworth@#{$CONFIG[:domain]}>/
      end

      should "create changed mail as expected" do
        @expected.subject = '[Jobsworth] Resolved: [#1] Test -> Open [Test Project] (Erlend Simonsen)'
        @expected['Mime-Version'] = '1.0'
        @expected.body    = read_fixture('changed')
        @work_log.update_attributes(:body => "Task Changed")
        notification = Notifications.changed(@deliveries.first)
        assert @user.can_view_task?(@task)
        assert_match  /tasks\/view/,  notification.body.to_s
        assert_equal @expected.body.to_s, notification.body.to_s

        # check Message-ID
        assert notification.to_s =~ /Message\-ID:\s+<#{@deliveries.first.work_log.task.task_num}.#{@deliveries.first.work_log.id}.jobsworth@#{$CONFIG[:domain]}>/
      end

      should "not escape html in email" do
        html = '<strong> HTML </strong> <script type = "text/javascript"> alert("XSS");</script>'
        @work_log.update_attributes(:body => html)
        notification = Notifications.changed(@deliveries.first)
        assert_not_nil notification.body.to_s.index(html)
      end

      should "should have 'text/plain' context type" do
        @work_log.update_attributes(:body => "Task changed")
        notification = Notifications.changed(@deliveries.first)
        assert_match /text\/plain/, notification.content_type
      end

      context "threading emails" do
        setup do
          if AccessLevel.count == 0
            AccessLevel.create!(:name=>'public')
            AccessLevel.create!(:name=>'private')
          end

          @user2 = users(:tester)

          @task.work_logs.delete_all

          @private_worklog_1 = WorkLog.make(:user => @user, :task => @task, :access_level_id => AccessLevel.find_by_name("private").id, :started_at => Time.now.ago(-3.hours))
          @public_worklog_1 = WorkLog.make(:user => @user, :task => @task, :access_level_id => AccessLevel.find_by_name("public").id, :started_at => Time.now.ago(-4.hours))
          @private_worklog_2 = WorkLog.make(:user => @user, :task => @task, :access_level_id => AccessLevel.find_by_name("private").id, :started_at => Time.now.ago(-7.hours))
          @public_worklog_2 = WorkLog.make(:user => @user, :task => @task, :access_level_id => AccessLevel.find_by_name("public").id, :started_at => Time.now.ago(-9.hours))

          @delivery_private_1 = EmailDelivery.create(:work_log => @private_worklog_1, :email => @user2.email, :user => @user2)
          @delivery_public_1 = EmailDelivery.create(:work_log => @public_worklog_1, :email => @user.email, :user => @user)
          @delivery_private_2 = EmailDelivery.create(:work_log => @private_worklog_2, :email => @user2.email, :user => @user2)
          @delivery_public_2 = EmailDelivery.create(:work_log => @public_worklog_2, :email => @user.email, :user => @user)
        end

        should "public worklog email threading headers are set" do
          email = Notifications.created(@delivery_public_2)

          # check Message-ID
          assert email.to_s =~ /Message\-ID:\s*<#{@task.task_num}.#{@delivery_public_2.work_log.id}.jobsworth@#{$CONFIG[:domain]}>/
          # References
          assert email.to_s =~ /References:\s*<#{@task.task_num}.#{@public_worklog_1.id}.jobsworth@#{$CONFIG[:domain]}>/
        end

        should "private worklog email threading headers are set" do
          email = Notifications.created(@delivery_private_2)

          # check Message-ID
          assert email.to_s =~ /Message\-ID:\s*<#{@task.task_num}.#{@delivery_private_2.work_log.id}.jobsworth@#{$CONFIG[:domain]}>/
          # References
          assert email.to_s =~ /References:\s*<#{@task.task_num}.#{@private_worklog_1.id}.jobsworth@#{$CONFIG[:domain]}>/
        end

        should "no References header if no previous work_log" do
          email = Notifications.created(@delivery_private_1)

          # check Message-ID
          assert email.to_s =~ /Message\-ID:\s*<#{@task.task_num}.#{@delivery_private_1.work_log.id}.jobsworth@#{$CONFIG[:domain]}>/
          # References
          assert email.to_s !~ /References:/
        end
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
        @work_log = WorkLog.make(:user => @user, :task => @task, :body => "Task Changed")
        @delivery = @work_log.email_deliveries.make(:email => @user.email, :user=>@user)
        notification = Notifications.changed(@delivery)
        assert_nil notification.body.to_s.index("/tasks/view/")
      end

      should "create created mail without view task link" do
        @work_log = WorkLog.make(:user => @user, :task => @task)
        @delivery = @work_log.email_deliveries.make(:email=> @user.email, :user=>@user)
        notification = Notifications.created(@delivery)
        assert_nil notification.body.to_s.index("/tasks/view/")
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

