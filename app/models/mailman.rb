# encoding: UTF-8
# Receive and handle emails sent to tasks

class Mailman < ActionMailer::Base
  # The marker in the email body that shows where the new content ends
  BODY_SPLIT = "o------ please reply above this line ------o"

  def receive(mail)
    begin
      super
    rescue Exception => e
      File.open(File.join(Rails.root,"failed_#{Time.now.to_i}.eml"), 'w') { |f| f.write(e.inspect); f.write(mail)}
      raise e
    end
  end

  ### Mailman::Email provides a way to extract content from incoming email
  class Email
    attr_accessor :to, :from, :body, :subject, :user, :company, :email_address
    def initialize(email)
      @to, @from = email.to.join(", "), email.from.join(", ")
      @body, @subject = get_body(email), email.subject
      @email_address = EmailAddress.find_or_create_by_email(@from)
    end

    private
    def get_body(email)
      body = nil
      if email.multipart? then
        email.parts.each do |m|
          next if body

          if m.content_type =~ /text\/plain/i
            body = m.body.to_s.force_encoding(m.charset || "US-ASCII").encode(Encoding.default_internal)
          elsif m.multipart?
            body = get_body(m)
          end
        end
      end

      body ||= email.body.to_s.force_encoding(email.charset || "US-ASCII").encode(Encoding.default_internal)
      body = Mailman.clean_body(body)
      body = CGI::escapeHTML(body)
      return body
    end
  end

  # helper method to remove email reply noise from the body
  def self.clean_body(body)
    new_body_end = body.to_s.index(Mailman::BODY_SPLIT) || body.to_s.length
    body = body.to_s[0, new_body_end].strip

    lines = body.to_s.split("\n")
    while lines.any?
      line = lines.last.strip

      if line.blank? or line.match(/^[<>]+$/) or line.match(/.* wrote:/)
        lines.pop
      else
        break
      end
    end

    return lines.join("\n")
  end

  def bad_subject?(sub)
    return false if sub.nil?
    arr = YAML.load_file(File.join(Rails.root, '/config/bad_subjects.yml'))
    subjects= arr["bad_subject"].collect{|s| s.strip}
    subjects.include?(sub.strip)
  end

  def receive(email)
    e = Mailman::Email.new(email)
    if e.subject.blank?
      response_line= "the subject in your email was blank."
    end
    if e.body.blank?
      response_line= "the body of your email was blank or you didn't reply above the line."
    end
    if email.attachments.detect { |file| file.body.to_s.size > 5*1024*1024 }
      response_line= "you attached a file over 5Mb."
    end
    if(email.date < (Time.now- 1.week))
      response_line= "your email was over a week old (or your clock is badly adjusted)."
    end
    if bad_subject?(e.subject)
      response_line= "the subject of your email was empty or it was too generic without providing a summary of the issue."
    end

    company = nil
    (email.to+Array.wrap(email.resent_to)).each do |to|
      next unless to.include?($CONFIG[:domain])
      subdomain = to.split('@')[1].split('.')[0]
      company ||= Company.find_by_subdomain(subdomain)
    end
    # if company not found but we're using a single company install, just
    # use that one
    company ||= Company.first if Company.count == 1
    if company
      e.company = company
      e.user = User.by_email(e.from).where("company_id = ?", company.id).first
    end

    if (!e.user.nil? and (!e.user.active))
      response_line= "You can not send emails to Jobsworth, because you are an inactive user."
    end
    if !response_line.nil?
      Notifications.response_to_invalid_email(email.from.first, response_line).deliver
      return false
    end

    target = target_for(email, company)
    if target and target.is_a?(Task)
      add_email_to_task(e, email, target)
    elsif target and target.is_a?(Project)
      create_task_from_email(e, email, target)
    else
      Notifications.unknown_from_address(email.from.first, company.subdomain).deliver
    end
    return e
  end

  private

  # Returns the target location for the given email. Could be
  # a Task, a Project or nil.
  def target_for(email, company)
    target = nil
    (email.to+Array(email.resent_to)).each do |to|
      if to.include?("task-")
        _, task_num = /task-(\d+).*@.*/.match(to).to_a
        if task_num.to_i > 0
          target = Task.where("company_id = ? AND task_num = ?", company.id, task_num).first
        end
      end
    end

    target ||= default_project(company)
    return target
  end

  # Returns the default email project for company, or nil
  # if none.
  def default_project(company)
    id = company.preference("incoming_email_project")
    return company.projects.find_by_id(id)
  end

  def add_email_to_task(e, email, task)
    return if !should_accept_email?(email, task)
    files = save_attachments(e, email, task)

    if task.done?
      # need to reopen task so incoming comment doens't get closed
      task.update_attributes(:completed_at => nil,
                             :status => Task.status_types.index("Open"))
    end
    task.updated_by_id= e.email_address.id
    task.save!
    w = WorkLog.new(:user => e.user, :company => task.project.company,
                    :customer => task.project.customer, :email_address => e.email_address,
                    :task => task, :started_at => Time.now.utc,
                    :duration => 0, :log_type => EventLog::TASK_COMMENT,
                    :body => e.body)
    w.save

    w.event_log.user = e.user
    w.event_log.save
    send_changed_emails_for_task(w, files)
    Trigger.fire(task, Trigger::Event::UPDATED)
  end

  # Returns true if the email should be accepted
  def should_accept_email?(email, task)
    # for now, let's try just accepting everything
    return true
  end

  def save_attachments(e, email, task)
    files = []
    if email.has_attachments?
      files = email.attachments.map do |attachment|
        add_attachment(e, task, attachment)
      end
    end
    return files.compact
  end

  def add_attachment(e, target, attachment)
    tempfile = File.open(Rails.root.join('tmp', attachment.original_filename.gsub(' ', '_').gsub(/[^a-zA-Z0-9_\.]/, '')), 'w')
    tempfile.write_nonblock(attachment.body)
    file= target.add_attachment(File.open(tempfile.path), e.user)
    File.delete(tempfile.path)
    return file
  end

  def create_task_from_email(e, email, project)
    task = Task.new(:name => email.subject,
                    :project => project,
                    :company => project.company,
                    :description => e.body,
                    :duration => 0,
                    :updated_by_id=> e.email_address.id)
    task.set_default_properties
    begin
      task.save(:validate=>false)
    rescue ActiveRecord::RecordNotUnique
      task.save(:validate=>false)
    end
    attach_users_to_task(task, email)
    task.save(:validate=>false)
    attach_customers_to_task(task)
    save_attachments(e, email, task)

    # need to do without_validations to get around validation
    # errors on custom attributes
    task.save(:validate=> false)
    work_log= WorkLog.create_task_created!(task, e.user)
    work_log.email_address= e.email_address
    work_log.save!
    work_log.notify()
    Trigger.fire(task, Trigger::Event::CREATED)
  end

  def attach_users_to_task(task, email)
    (Array(email.from) + Array(email.cc) ).each do |email_addr|
      attach_user_or_email_address(email_addr, task, task.watchers)
    end
    (email.to || []).each do |email_addr|
      attach_user_or_email_address(email_addr, task, task.owners)
    end
  end

  def attach_user_or_email_address(email, task, users)
    user = task.project.company.users.active.by_email(email.strip).first
    if user
      users << user
    else
      unless  task.company.suppressed_email_addresses.try(:include?, email.strip)
        task.email_addresses<< EmailAddress.find_or_create_by_email(email.strip)
      end
    end
  end

  def attach_customers_to_task(task)
    task.users.each do |user|
      if user.customer and !task.customers.include?(user.customer)
        task.customers << user.customer
        user.customer.users.auto_add.each do |u|
           task.watchers << u unless task.users.include?(u)
        end
      end
    end
  end

  def send_changed_emails_for_task(work_log, files)
    user = work_log.user
    tmp=user.receive_own_notifications
    user.receive_own_notifications=false
    #skip save! if incoming email came from unknown user
    unless user.new_record?
      user.save!
      send_worklog_notification(work_log, files)
      user.receive_own_notifications=tmp
      user.save!
    else
      send_worklog_notification(work_log, files)
    end
  end

  def send_worklog_notification(work_log, files)
      work_log.notify(files)
  end
end
