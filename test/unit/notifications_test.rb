require 'test_helper'
require 'notifications'


class NotificationsTest < ActiveSupport::TestCase
  CHARSET = 'UTF-8'

  context 'a normal notification' do
    setup do
      # need to hard code these configs because the fixtured have hard coded values
      Setting.domain = 'clockingit.com'
      Setting.email_domain = Setting.domain.gsub(/:\d+/, '')
      Setting.productName = 'Jobsworth'

      @expected = Mail.new
      @expected.content_type "text/plain; charset=#{CHARSET}"

      @expected.from = "#{Setting.from}@#{Setting.email_domain}"
      @expected.reply_to = 'task-1@cit.clockingit.com'
      @expected.to = 'admin@clockingit.com'
      @expected['Mime-Version'] = '1.0'
      @expected.date = Time.now

      @company = Company.make
    end

    context 'with a user with access to the task' do
      setup do
        @task = TaskRecord.make(:company => @company)
        @user = User.make(:admin, :company => @company)
        @user.projects<<@task.project
        @user.save!
        @work_log = WorkLog.make(:user => @user, :task => @task)
        @deliveries = []
        @task.users_to_notify(@user).each do |recipient|
          @deliveries << @work_log.email_deliveries.make(:email => recipient.email, :user => recipient)
        end
      end

      should 'create created mail as expected' do
        @task.company.properties.destroy_all
        @task.company.create_default_properties
        @task.company.properties.each { |p|
          @task.set_property_value(p, p.default_value)
        }
        notification = Notifications.created(@deliveries.first)
        assert_equal @task.users_to_notify(@user).map(&:email), [@user.email]
        assert @user.can_view_task?(@task)
        assert /#{@task.description}/ =~ notification.body.to_s

        # check Message-ID
        assert notification.to_s =~ /Message\-ID:\s+<#{@deliveries.first.work_log.task.task_num}.#{@deliveries.first.work_log.id}.jobsworth@#{Setting.domain}>/
      end

      should 'create created mail with first comment' do
        @task.company.properties.destroy_all
        @task.company.create_default_properties
        @task.company.properties.each { |p|
          @task.set_property_value(p, p.default_value)
        }
        notification = Notifications.created(@deliveries.first)

        assert !(notification.to_s =~ /Comment:/)

        # create another work log that will act as the first comment
        WorkLog.make(:user => @user, :task => @task, :body => 'Hello World')

        notification = Notifications.created(@deliveries.first.reload)

        assert(notification.to_s =~ /\r\nHello World/, notification.to_s)
      end

      should 'create changed mail as expected' do
        @work_log.update_attributes(:body => 'Task Changed')
        notification = Notifications.changed(@deliveries.first)
        assert @user.can_view_task?(@task)
        assert /#{@task.description}/ =~ notification.body.to_s

        # check Message-ID
        assert notification.to_s =~ /Message\-ID:\s+<#{@deliveries.first.work_log.task.task_num}.#{@deliveries.first.work_log.id}.jobsworth@#{Setting.domain}>/
      end

      should 'not escape html in email' do
        html = '<strong> HTML </strong> <script type = "text/javascript"> alert("XSS");</script>'
        @work_log.update_attributes(:body => html)
        notification = Notifications.changed(@deliveries.first)
        assert_not_nil notification.body.to_s.index(html)
      end

      should "should have 'text/plain' context type" do
        @work_log.update_attributes(:body => 'Task changed')
        notification = Notifications.changed(@deliveries.first)
        assert_match /text\/plain/, notification.content_type
      end

      context 'threading emails' do
        setup do
          if AccessLevel.count == 0
            AccessLevel.create!(:name => 'public')
            AccessLevel.create!(:name => 'private')
          end

          @user2 = User.make

          @task.work_logs.delete_all

          @private_worklog_1 = WorkLog.make(:user => @user, :task => @task, :access_level_id => AccessLevel.find_by(:name => 'private').id, :started_at => Time.now.ago(-3.hours))
          @public_worklog_1 = WorkLog.make(:user => @user, :task => @task, :access_level_id => AccessLevel.find_by(:name => 'public').id, :started_at => Time.now.ago(-4.hours))
          @private_worklog_2 = WorkLog.make(:user => @user, :task => @task, :access_level_id => AccessLevel.find_by(:name => 'private').id, :started_at => Time.now.ago(-7.hours))
          @public_worklog_2 = WorkLog.make(:user => @user, :task => @task, :access_level_id => AccessLevel.find_by(:name => 'public').id, :started_at => Time.now.ago(-9.hours))

          @delivery_private_1 = EmailDelivery.create(:work_log => @private_worklog_1, :email => @user2.email, :user => @user2)
          @delivery_public_1 = EmailDelivery.create(:work_log => @public_worklog_1, :email => @user.email, :user => @user)
          @delivery_private_2 = EmailDelivery.create(:work_log => @private_worklog_2, :email => @user2.email, :user => @user2)
          @delivery_public_2 = EmailDelivery.create(:work_log => @public_worklog_2, :email => @user.email, :user => @user)
        end

        should 'public worklog email threading headers are set' do
          email = Notifications.created(@delivery_public_2)

          # check Message-ID
          assert email.to_s =~ /Message\-ID:\s*<#{@task.task_num}.#{@delivery_public_2.work_log.id}.jobsworth@#{Setting.domain}>/
          # References
          assert email.to_s =~ /References:\s*<#{@task.task_num}.#{@public_worklog_1.id}.jobsworth@#{Setting.domain}>/
        end

        should 'private worklog email threading headers are set' do
          email = Notifications.created(@delivery_private_2)

          # check Message-ID
          assert email.to_s =~ /Message\-ID:\s*<#{@task.task_num}.#{@delivery_private_2.work_log.id}.jobsworth@#{Setting.domain}>/
          # References
          assert email.to_s =~ /References:\s*<#{@task.task_num}.#{@private_worklog_1.id}.jobsworth@#{Setting.domain}>/
        end

        should 'no References header if no previous work_log' do
          email = Notifications.created(@delivery_private_1)

          # check Message-ID
          assert email.to_s =~ /Message\-ID:\s*<#{@task.task_num}.#{@delivery_private_1.work_log.id}.jobsworth@#{Setting.domain}>/
          # References
          assert email.to_s !~ /References:/
        end
      end

    end

    context 'a user without access to the task' do
      setup do
        @task = TaskRecord.make
        @user = User.make
        @user.project_permissions.destroy_all
        assert !@task.project.users.include?(@user)
      end

      should 'create changed mail without view task link' do
        @work_log = WorkLog.make(:user => @user, :task => @task, :body => 'Task Changed')
        @delivery = @work_log.email_deliveries.make(:email => @user.email, :user => @user)
        notification = Notifications.changed(@delivery)
        assert_nil notification.body.to_s.index('/tasks/view/')
      end

      should 'create created mail without view task link' do
        @work_log = WorkLog.make(:user => @user, :task => @task)
        @delivery = @work_log.email_deliveries.make(:email => @user.email, :user => @user)
        notification = Notifications.created(@delivery)
        assert_nil notification.body.to_s.index('/tasks/view/')
      end
    end
  end

  private

  def encode(subject)
    quoted_printable(subject, CHARSET)
  end
end

