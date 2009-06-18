require File.dirname(__FILE__) + '/../test_helper'

class MailmanTest < ActiveSupport::TestCase
  fixtures :tasks, :users, :companies
  
  def setup
    @task = Task.first
    @company = @task.company
    $CONFIG[:domain] = @company.subdomain

    @user = @company.users.first
    @task.users << @user
    @task.save!

    @tmail = TMail::Mail.new
    @tmail.to = "task-#{ @task.task_num }@#{ $CONFIG[:domain ]}"
    @tmail.from = @user.email
    @tmail.subject = "test subject"
    @tmail.body = "AAA\n#{ Mailman::BODY_SPLIT }\nBBB"

    WorkLog.delete_all
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

    new_body_end = @tmail.body.index(Mailman::BODY_SPLIT)
    trimmed_body = @tmail.body[0, new_body_end]
    assert_equal trimmed_body, log.body
  end

  def test_body_with_no_trim_works
    assert_equal 0, WorkLog.count
    @tmail.body = "AAAA"
    email = Mailman.receive(@tmail.to_s)

    log = WorkLog.first
    assert_not_nil log
    assert_equal "AAAA", log.body
  end

end
