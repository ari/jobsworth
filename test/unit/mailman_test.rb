require "test_helper"

class MailmanTest < ActionMailer::TestCase
  setup do
    @user = User.make
    @company = @user.company
    Setting.domain = @company.subdomain
    Setting.productName = "Jobsworth"
    @task = TaskRecord.make(:company => @user.company, :project => Project.make(:company => @user.company, :customer => @user.customer))
    @task.owners << @user
    @task.watchers << User.make(:company => @user.company)
    @task.save!
    @tmail = Mail.new(test_mail)
    @tmail.date= Time.now
    WorkLog.delete_all
    ActionMailer::Base.deliveries.clear
  end

  def shared_tests_for_invalid_email(mail)
    assert_equal 0, WorkLog.count
    email = Mailman.receive(mail.to_s)
    assert_equal 0, WorkLog.count
    message= ActionMailer::Base.deliveries.first
    assert_equal message.to, mail.from
    assert_match /Thank you for your email which was forwarded to the .*\n*
Please fix this problem and try sending your email again.\n*
Thank you,
Jobsworth/m, message.body.to_s
  end

  def self.shared_examples_for_triggers
    should "should set tasks due date" do
      assert_in_delta @task.due_date, (Time.now.utc+4.days), 10.minutes
    end
    should "create work log, when trigger set due date " do
      assert_not_nil @task.work_logs.where("work_logs.body like 'This task was updated by trigger\n- Due: #{I18n.l(@task.due_at, format: "%A, %d %B %Y")}\n'").last
    end

    should "should reassign taks to user" do
      assert_equal [@user], @task.owners
    end
    should "create worklog, when trigger reassign task to user" do
      assert_not_nil @task.work_logs.where("work_logs.body like 'This task was updated by trigger\n- Assignment: #{@task.owners_to_display}\n'").last
    end
    should "be equal worklog's email address and email address of incoming email." do
      assert_equal @task.work_logs.last.email_address.email, @tmail.from.last
    end
  end

  context "email encoding" do
    should "receive utf8 encoded email" do
      (Company.all - [@company]).each{ |c| c.destroy}
      @company.preference_attributes= { "incoming_email_project" => @company.projects.first.id }
      assert Mailman.receive(File.read(File.join(Rails.root,'test/fixtures/emails', 'zabbix_utf8.eml')))
    end

    should "receive iso 88859 encoded email" do
      (Company.all - [@company]).each{ |c| c.destroy}
      @company.preference_attributes= { "incoming_email_project" => @company.projects.first.id }
      assert Mailman.receive(File.read(File.join(Rails.root,'test/fixtures/emails', 'iso_8859_1.eml')))
    end

    should "receive windows 1252 encoded email" do
      (Company.all - [@company]).each{ |c| c.destroy}
      @company.preference_attributes= { "incoming_email_project" => @company.projects.first.id }
      count = TaskRecord.count
      assert Mailman.receive(File.read(File.join(Rails.root,'test/fixtures/emails', 'windows_1252.eml')))
      assert_equal count +1, TaskRecord.count
    end

    should "receive invalid byte sequence in UTF-8" do
      (Company.all - [@company]).each{ |c| c.destroy}
      @company.preference_attributes= { "incoming_email_project" => @company.projects.first.id }
      count = TaskRecord.count
      assert Mailman.receive(File.read(File.join(Rails.root,'test/fixtures/emails', 'invalid_utf8_sequence.eml')))
      assert_equal count + 1, TaskRecord.count
    end
  end

  context "invalid emails" do
    should "response to email with blank subject" do
      @tmail.subject=""
      shared_tests_for_invalid_email(@tmail)
    end

    should "response to email with blank body" do
      @tmail.body = ""
      shared_tests_for_invalid_email(@tmail)
    end

    should "response to email with big file" do
      @tmail.add_file(:filename=> '12345.png', :content=> "123456"*1024*1024)
      assert_equal 0, @task.attachments.count
      shared_tests_for_invalid_email(@tmail)
      assert_equal 0, @task.attachments.count
    end

    should "response to email with old date" do
      @tmail.date = Time.now- 2.weeks
      shared_tests_for_invalid_email(@tmail)
    end

    should "response to email with bad subject" do
      @tmail.subject= "Fwd:"
      shared_tests_for_invalid_email(@tmail)
    end

    should "response to email from inactive user" do
      @user.active= false
      @user.save!
      @tmail.from = @user.email
      shared_tests_for_invalid_email(@tmail)
    end
  end

  context "on existing task" do
    should "receive sets basic email properties" do
      email = Mailman.receive(@tmail.to_s)

      assert email
      assert_equal @tmail.from.first, email.from
      assert_equal @tmail.subject, email.subject
    end

    should "receive and set user and company" do
      email = Mailman.receive(@tmail.to_s)

      assert_equal @task.company, email.company
      assert_equal @user, email.user
    end

    should "receive and create work log" do
      assert_equal 0, WorkLog.count
      email = Mailman.receive(@tmail.to_s)

      log = WorkLog.first
      assert_not_nil log
      assert_equal @task, log.task
      assert_equal @user, log.user
    end

    should "task be touched if two successive comments are from the same user" do
      Mailman.receive(@tmail.to_s)
      @task.reload
      updated_at = @task.updated_at

      sleep(1)

      Mailman.receive(@tmail.to_s)
      @task.reload

      assert_not_equal @task.updated_at, updated_at
    end

    should "body gets trimmed properly" do
      assert_equal 0, WorkLog.count

      clear_users(@task)
      email = Mailman.receive(@tmail.to_s)

      log = WorkLog.first
      assert_not_nil log

      assert_equal "Comment", log.body
    end

    #in the db must be stored unescaped values
    should "body not be escaped" do
      assert_equal 0, WorkLog.count

      mail = Mail.new
      mail.to = @tmail.to
      mail.from = @tmail.from
      mail.body = "<b>test</b>"
      mail.subject = "test subject"
      email = Mailman.receive(mail.to_s)

      log = WorkLog.first
      assert_not_nil log

      assert_not_nil log.body.index("<b>test</b>")
    end

    should "body with no trim works" do
      assert_equal 0, WorkLog.count
      clear_users(@task)

      mail = Mail.new
      mail.to = "task-#{ @task.task_num }@#{ Setting.domain }"
      mail.from = @user.email
      mail.body = "AAAA"
      mail.subject = "test subject"
      email = Mailman.receive(mail.to_s)

      log = WorkLog.first
      assert_not_nil log
      assert_equal "AAAA", log.body
      assert_equal log.project, @task.project
      assert_equal log.company, @task.company
    end

    should "clean body removes comment junk" do
      str = "a comment
< old comment...

  <
On 15/09/2009, at 12:39 PM, support@ish.com.au wrote:
>
>

o------ please reply above this line ------o
"

      assert_equal "a comment\n< old comment...", Mailman::Email.clean_body(str)
    end

    should "attachments get added to tasks" do
      assert_equal 0, @task.attachments.count
      email = Mailman.receive(@tmail.to_s)
      assert_equal 1, @task.attachments.count
    end

    should "closed tasks get reopened" do
      @task.update_attributes(
        :status => TaskRecord.status_types.index("Closed"),
        :completed_at => Time.now
      )
      assert @task.done?

      Mailman.receive(@tmail.to_s)
      assert !@task.reload.done?
    end

    should "in progress tasks don't get reopened" do
      status = TaskRecord.status_types.index("In Progress")
      @task.update_attributes(:status => status)
      Mailman.receive(@tmail.to_s)
      assert_equal status, @task.reload.status
    end
  end

  context "A forwarded to task email" do
    setup do
      @tmail.resent_from =@tmail.from
      @tmail.resent_to = @tmail.to
      @tmail.to="someemail@somesrever.com"
    end
    should "be added to task" do
      count = @task.work_logs.count
      Mailman.receive(@tmail.to_s)
      assert_equal count + 1, @task.work_logs.count
      assert_match /Comment/, @task.work_logs.last.body
    end
  end

  context "A normal email" do
    context "to a task with watchers" do
      setup do
        assert_emails 0

        @task.unknown_emails = "test1@example.com,test2@example.com"
        @task.save!

        assert_equal 2, @task.users.count
      end

      should "deliver changed emails to users, watcher and email watchers" do
        Mailman.receive(@tmail.to_s)
        emails_to_send = @task.users.count
        emails_to_send += @task.unknown_emails.split(",").length
        if @task.users.include?(@user) or @task.watchers.include?(@user)
          emails_to_send -= 1 # because sender should be excluded
        end

        assert_emails emails_to_send
      end

      should "not re-add user as watchers" do
        user_count = @task.users.count
        watcher_count = @task.watchers.count
        owner_count = @task.owners.count

        @tmail.from = @user.email
        @tmail.cc = @user.email
        @tmail.to = @user.email

        Mailman.receive(@tmail.to_s)

        @task.reload
        assert_equal user_count, @task.users.count
        assert_equal watcher_count, @task.watchers.count
        assert_equal owner_count, @task.owners.count
      end

      should "not add unknown as watcher" do
        @tmail.cc = "unknownuser@domain.com.au"
        Mailman.receive(@tmail.to_s)
        assert !@task.email_addresses(true).include?(EmailAddress.find_by_email("unknownuser@domain.com.au"))
      end

      should "not add cc as watcher" do
        user_count = @task.users.count
        watcher_count = @task.watchers.count
        owner_count = @task.owners.count

        user = User.make(:company => @user.company)
        @tmail.from = user.email
        @tmail.cc = user.email
        @tmail.to = user.email

        Mailman.receive(@tmail.to_s)

        @task.reload
        assert_equal user_count, @task.users.count
        assert_equal watcher_count, @task.watchers.count
        assert_equal owner_count, @task.owners.count
      end

      should "send files with changed email" do
        Mailman.receive(@tmail.to_s)
        mail= ActionMailer::Base.deliveries.first
        assert mail.has_attachments?
        assert_equal @tmail.attachments.first.filename, mail.attachments.first.filename
        assert_equal @tmail.attachments.first.body.to_s, mail.attachments.first.body.to_s
      end

      should "create a relation email_delivery to email_addresses of the people who received notification emails" do
        Mailman.receive(@tmail.to_s)
        emails = @task.work_logs.reload.comments.last.email_deliveries.map{|ed| ed.email }

        assert emails.include?("test1@example.com")
        assert emails.index("test2@example.com")
      end

      context "from unknown user" do
        setup do
          @tmail.from = "unknownuser@domain.com.au"
        end

        should "create new email address" do
          assert_difference "EmailAddress.count", +1 do
            Mailman.receive(@tmail.to_s)
          end
          assert_equal "unknownuser@domain.com.au", @task.work_logs.last.email_address.email
          assert @task.reload.email_addresses.include?(EmailAddress.find_by_email("unknownuser@domain.com.au"))
        end

        should "not re-add unknown as watchers" do
          ea = EmailAddress.create(:company => @company, :email => "unknownuser@domain.com.au")

          @task.email_addresses << ea
          count = @task.email_addresses.count
          @tmail.from = ea.email

          Mailman.receive(@tmail.to_s)

          assert_equal count, @task.reload.email_addresses.count
        end

        should "not create new user" do
          assert_difference "WorkLog.count", +1 do
            user_count = User.count
            Mailman.receive(@tmail.to_s)
            assert_equal user_count, User.count
          end
        end

        context "when on update triggers exist: set due date and reassign task to user" do
          setup do
            Trigger.destroy_all
            Trigger.new(:company=> @user.company, :event_id => Trigger::Event::UPDATED, :actions => [Trigger::SetDueDate.new(:days=>4)]).save!
            user = User.make(:company => @user.company)
            Trigger.new(:company=> @user.company, :event_id => Trigger::Event::UPDATED, :actions => [Trigger::ReassignTask.new(:user=>user)]).save!
            @task.due_at = Time.now + 1.month
            @task.save!
            assert !@task.users.include?(user)
            @task.work_logs.destroy_all
            Mailman.receive(@tmail.to_s)
            @task.reload

            @user = user
          end
          shared_examples_for_triggers
        end
      end

      context "when on update triggers exist: set due date and reassign task to user" do
        setup do
          Trigger.destroy_all
          Trigger.new(:company=> @user.company, :event_id => Trigger::Event::UPDATED, :actions => [Trigger::SetDueDate.new(:days=>4)]).save!
          user = User.make(:company => @user.company)
          Trigger.new(:company=> @user.company, :event_id => Trigger::Event::UPDATED, :actions => [Trigger::ReassignTask.new(:user=>user)]).save!
          @task.due_at = Time.now + 1.month
          @task.save!
          assert !@task.users.include?(user)
          Mailman.receive(@tmail.to_s)
          @task.reload

          @user = user
        end
        shared_examples_for_triggers
      end
    end
  end

  context "an email with no task information" do
    setup do
      @to = "anything@#{ Setting.domain }.com"
      @from = @user.email
      @tmail.to=@to
      @tmail.from=@from

      @project = @company.projects.last
      @company.preference_attributes = { "incoming_email_project" => @project.id }

      # need an admin user
      @company.users.first.update_attribute(:admin, true)
    end

    should "be added to incoming_email_project preference for company" do
      count = @project.tasks.count
      Mailman.receive(@tmail.to_s)

      assert_equal count + 1, @project.tasks.count
      task = TaskRecord.order("id desc").first

      assert_equal @tmail.subject, task.name
      assert_match /Comment/, task.work_logs.last.body
      assert_equal task.work_logs.last.project, @project
    end

    should "save incoming email's attachments" do
      project_files_count = ProjectFile.count
      Mailman.receive(@tmail.to_s)
      task = TaskRecord.order("id desc").first
      assert_equal project_files_count + 1, ProjectFile.count
      assert_equal 1, task.attachments.size
    end

    should "have the original senders email in WorkLog.email_address if no user with that email" do
      # need only one company
      Company.all.each { |c| c.destroy if c != @company }

      count = @project.tasks.count
      email = Mailman.receive(@tmail.to_s)

      assert_not_nil email.email_address
      assert_equal count + 1, @project.tasks.count
      task = TaskRecord.order("id desc").first

      assert_equal task.work_logs.first.email_address.email, @from
    end

    should "set task properties default values" do
      first_property = Property.make(:company => @project.company)
      second_property = Property.make(:company => @project.company)
      Mailman.receive(@tmail.to_s)
      task = TaskRecord.order("id desc").first
      assert_equal @tmail.subject, task.name
      assert_equal task.property_value(first_property), first_property.default_value
      assert_equal task.property_value(second_property), second_property.default_value
    end

    should "add customer.auto_add users as watchers" do
      user = @project.company.users.make(:customer=>Customer.make(:company=>@project.company))
      user1 = @project.company.users.make(:customer=>user.customer, :auto_add_to_customer_tasks=>true)
      @tmail.from=user.email
      Mailman.receive(@tmail.to_s)
      task = TaskRecord.order("id desc").first
      assert task.watchers.include?(user1)
    end

    context "when on create triggers exist: set due date and reassign task to user" do
      setup do
        Trigger.destroy_all
        Trigger.new(:company=> @user.company, :event_id => Trigger::Event::CREATED, :actions => [Trigger::SetDueDate.new(:days=>4)]).save!
        @user= User.last
        Trigger.new(:company=> @user.company, :event_id => Trigger::Event::CREATED, :actions => [Trigger::ReassignTask.new(:user=>@user)]).save!
        Mailman.receive(@tmail.to_s)
        @task= TaskRecord.last
      end
      shared_examples_for_triggers
    end

    context "from unknown user" do
      setup do
        @from = "unknownuser@domain.com.au"
      end
      setup do
        Trigger.destroy_all
        Trigger.new(:company=> @user.company, :event_id => Trigger::Event::CREATED, :actions => [Trigger::SetDueDate.new(:days=>4)]).save!
        @user= User.last
        Trigger.new(:company=> @user.company, :event_id => Trigger::Event::CREATED, :actions => [Trigger::ReassignTask.new(:user=>@user)]).save!
        Mailman.receive(@tmail.to_s)
        @task= TaskRecord.last
      end
      shared_examples_for_triggers
    end
  end

  context "a single company install" do
    setup do
      # need an admin user for this
      @user = User.make(:admin, :company => @company)
      # need only one company
      Company.all.each { |c| c.destroy if c != @company }

      @project = @company.projects.last
      @company.preference_attributes = { "incoming_email_project" => @project.id }

      mail = test_mail("to@random.com", "from@random.com")
      @tmail = Mail.new(mail)
      @tmail.date= Time.now
    end

    should "add users to task as assigned" do
      @tmail.to = [ @tmail.to, User.first.email ]

      Mailman.receive(@tmail.to_s)

      task = TaskRecord.order("id desc").first
      assert task.users.include?(User.first)
    end

    should "add users in cc as watchers" do
      @tmail.cc = [ User.first.email ]
      Mailman.receive(@tmail.to_s)

      task = TaskRecord.order("id desc").first
      assert task.watchers.include?(User.first)
    end

    should "add sender to task" do
      user = User.first
      @tmail.from = user.email

      Mailman.receive(@tmail.to_s)

      task = TaskRecord.order("id desc").first
      assert task.users.include?(user)
    end

    should "add unknown(not associated with existed user) email address from to/from/cc headers to task's notify emails" do
      @tmail.cc= ["not.existed@domain.com"]
      @tmail.from = ["unknown@domain2.com"]
      @tmail.to << "another.user@domain3.com"
      Mailman.receive(@tmail.to_s)
      emails = TaskRecord.order("id desc").first.email_addresses.map{ |ea| ea.email}
      assert emails.include?("not.existed@domain.com")
      assert emails.include?("unknown@domain2.com")
      assert emails.include?("another.user@domain3.com")
    end

    should "link unknown email to existing EmailAddress" do
      ea = EmailAddress.create(:email => "unknown@domain2.com")
      @tmail.from = ["unknown@domain2.com"]
      @tmail.to << "another.user@domain3.com"

      Mailman.receive(@tmail.to_s)

      assert TaskRecord.order("id desc").first.email_addresses.include?(ea)
    end

    should "ignore suppressed email addresses from to/cc/from headers" do
      @tmail.cc= ["not.existed@domain.com"]
      @tmail.from = ["unknown@domain2.com"]
      @tmail.to << "another.user@domain3.com"
      @company.suppressed_email_addresses = "unknown@domain2.com, not.existed@domain.com"
      @company.save!
      Mailman.receive(@tmail.to_s)
      emails = TaskRecord.order("id desc").first.email_addresses.map{ |ea| ea.email}
      assert !emails.include?("not.existed@domain.com")
      assert !emails.include?("unknown@domain2.com")
      assert emails.include?("another.user@domain3.com")
    end

    should "deliver created email to creator" do
      assert_emails 0
      Mailman.receive(@tmail.to_s)
      assert ActionMailer::Base.deliveries.size > 0
      assert ActionMailer::Base.deliveries.detect {|email| email.to == @tmail.from}
    end

    should "add all customers that email users belong to to task" do
      user1 = User.first
      user1.customer = Customer.make(:company => @company, :name => "A")
      user1.save!
      user2 = User.make(
        :company => @company,
        :customer => Customer.make(:company => @company, :name => "B")
      )

      @tmail.from = user1.email
      @tmail.cc = user2.email

      Mailman.receive(@tmail.to_s)
      task = TaskRecord.order("id desc").first
      assert_equal 2, task.task_customers.length
      assert task.customers.include?(user1.customer)
      assert task.customers.include?(user2.customer)
    end

  end


  private

  def test_mail(to = nil, from = nil)
    from ||= @user.email
    to ||= "task-#{ @task.task_num }@#{ Setting.domain }"

    str = <<-EOS
Return-Path: <brad@lucky-dip.net>
X-Original-To: brad@lucky-dip.net
Delivered-To: brad@lucky-dip.net
Received: by clamps.lucky-dip.net (Postfix, from userid 65534)
  id 75B711BAB20; Fri, 19 Jun 2009 10:40:51 +1000 (EST)
X-Spam-Checker-Version: SpamAssassin 3.2.4 (2008-01-01) on clamps
X-Spam-Level:
X-Spam-Status: No, score=0.2 required=5.0 tests=ALL_TRUSTED,TVD_RCVD_IP
  autolearn=no version=3.2.4
Received: from 192-168-1-106.tpgi.com.au (60-242-202-41.static.tpgi.com.au [60.242.202.41])
  by clamps.lucky-dip.net (Postfix) with ESMTPA id 19A1F1BAB20
  for <brad@lucky-dip.net>; Fri, 19 Jun 2009 10:40:49 +1000 (EST)
Message-Id: <291D51CB-24F1-431E-91A4-C099A8E60222@lucky-dip.net>
From: <#{ from }>
To: <#{ to }>
Content-Type: multipart/mixed; boundary=Apple-Mail-6-776876370
Mime-Version: 1.0 (Apple Message framework v935.3)
Subject: test subject
Date: Fri, 19 Jun 2009 10:40:48 +1000
X-Mailer: Apple Mail (2.935.3)


--Apple-Mail-6-776876370
Content-Type: text/plain;
  charset=US-ASCII;
  format=flowed
Content-Transfer-Encoding: 7bit

Comment


--Apple-Mail-6-776876370
Content-Disposition: inline;
  filename=blank.png
Content-Type: image/png;
  x-mac-creator=3842494D;
  x-unix-mode=0644;
  x-mac-type=504E4766;
  name="blank.png"
Content-Transfer-Encoding: base64

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
ZwAAAABJRU5ErkJggg==

--Apple-Mail-6-776876370
Content-Type: text/plain;
  charset=US-ASCII;
  format=flowed
Content-Transfer-Encoding: 7bit



--Apple-Mail-6-776876370--

EOS
  end

  def clear_users(task)
    # clear users so we don't get "Notification emails sent to..." message
    task.users.clear
    task.save!
  end
end
