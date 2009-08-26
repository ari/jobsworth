require File.dirname(__FILE__) + '/../test_helper'

class MailmanTest < ActiveSupport::TestCase
  fixtures :tasks, :users, :companies, :projects
  
  def setup
    @task = Task.first
    @company = @task.company
    $CONFIG[:domain] = @company.subdomain

    @user = @company.users.first
    @task.users << @user
    @task.watchers << @company.users[1]
    @task.save!

    @tmail = TMail::Mail.parse(test_mail)

    WorkLog.delete_all 
    ActionMailer::Base.deliveries.clear
  end

  def test_receive_sets_basic_email_properties
    email = Mailman.receive(@tmail.to_s)

    assert_not_nil email
    assert_equal @tmail.to.first, email.to
    assert_equal @tmail.from.first, email.from
    assert_equal @tmail.subject, email.subject
  end

  def test_receive_sets_user_and_company
    email = Mailman.receive(@tmail.to_s)

    assert_equal @task.company, email.company
    assert_equal @user, email.user
  end

  def test_receive_creates_work_log
    assert_equal 0, WorkLog.count
    email = Mailman.receive(@tmail.to_s)

    log = WorkLog.first
    assert_not_nil log
    assert_equal @task, log.task
    assert_equal @user, log.user
    assert_equal EventLog::TASK_COMMENT, log.log_type
  end
  
  def test_body_gets_trimmed_properly
    assert_equal 0, WorkLog.count
    email = Mailman.receive(@tmail.to_s)

    log = WorkLog.first
    assert_not_nil log

    assert_equal "Comment", log.body
  end

  def test_body_with_no_trim_works
    assert_equal 0, WorkLog.count

    mail = TMail::Mail.new
    mail.to = "task-#{ @task.task_num }@#{ $CONFIG[:domain ]}"
    mail.from = @user.email
    mail.body = "AAAA"
    email = Mailman.receive(mail.to_s)

    log = WorkLog.first
    assert_not_nil log
    assert_equal "AAAA", log.body
  end

  def test_attachments_get_added_to_tasks
    assert_equal 0, @task.attachments.count
    email = Mailman.receive(@tmail.to_s)
    assert_equal 1, @task.attachments.count
  end

  context "an email with no task information" do
    setup do
      @to = "anything@#{ $CONFIG[:domain] }"
      @from = @user.email

      @project = @company.projects.last
      @company.preference_attributes = { "incoming_email_project" => @project.id }
    end

    should "be added to incoming_email_project preference for company" do
      count = @project.tasks.count
      mail = test_mail(@to, @from)
      @tmail = TMail::Mail.parse(mail)
      Mailman.receive(@tmail.to_s)

      assert_equal count + 1, @project.tasks.count
      task = Task.find(:first, :order => "id desc")

      assert_equal @tmail.subject, task.name
      assert_equal "Comment", task.work_logs.first.body
    end

    should "have the original senders email in comment if no user with that email" do
      # need an admin user for this
      @company.users.first.update_attribute(:admin, true)
      # need only one company  
      Company.all.each { |c| c.destroy if c != @company }

      count = @project.tasks.count
      mail = test_mail("to@random", "from@random")
      @tmail = TMail::Mail.parse(mail)
      Mailman.receive(@tmail.to_s)

      assert_equal count + 1, @project.tasks.count
      task = Task.find(:first, :order => "id desc")
      assert_not_nil task.work_logs.first.body.index("Email from: from@random")
    end

    should "deliver changed emails to users, watcher and email watchers" do
      assert_emails 0

      @task.notify_emails = "test1@example.com,test2@example.com"
      @task.save!

      @task.task_owners.each { |n| n.update_attribute(:notified_last_change, true) }
      @task.notifications.each { |n| n.update_attribute(:notified_last_change, true) }

      Mailman.receive(@tmail.to_s)
      emails_to_send = @task.users.count + @task.watchers.count
      emails_to_send += @task.notify_emails.split(",").length
      if @task.users.include?(@user) or @task.watchers.include?(@user)
        emails_to_send -= 1 # because sender should be excluded
      end

      assert_emails emails_to_send
    end
  end

  context "a single company install" do
    setup do
      # need an admin user for this
      @company.users.first.update_attribute(:admin, true)
      # need only one company  
      Company.all.each { |c| c.destroy if c != @company }

      @project = @company.projects.last
      @company.preference_attributes = { "incoming_email_project" => @project.id }

      mail = test_mail("to@random", "from@random")
      @tmail = TMail::Mail.parse(mail)
    end

    should "add users to task as assigned" do
      @tmail.to = [ @tmail.to, User.first.email ]

      Mailman.receive(@tmail.to_s)

      task = Task.first(:order => "id desc")
      assert task.users.include?(User.first)
    end

    should "add users in cc as watchers" do
      @tmail.cc = [ User.first.email ]
      Mailman.receive(@tmail.to_s)

      task = Task.first(:order => "id desc")
      assert task.watchers.include?(User.first)
    end
  end


  private
  
  def test_mail(to = nil, from = nil)
    from ||= @user.email
    to ||= "task-#{ @task.task_num }@#{ $CONFIG[:domain ]}"

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
end
