# encoding: UTF-8
# Receive and handle emails sent to tasks

class Mailman < ActionMailer::Base
  # The marker in the email body that shows where the new content ends
  BODY_SPLIT = "o------ please reply above this line ------o"

  def self.receive(mail)
    begin
      super
    rescue Exception => e
      file_name = "failed_#{Time.now.to_i}.eml"
      File.open(File.join(Rails.root, file_name), 'w') { |f| f.write(e.inspect); f.write(e.backtrace); f.write(mail)}
      Rails.logger.error("exception receiving email. Saved to #{file_name}")
    end
  end

  ### Mailman::Email provides a way to extract content from incoming email
  class Email
    attr_accessor :to, :from, :body, :subject, :user, :company, :email_address

    def initialize(email)
      @to, @from = email.to.join(", "), email.from.join(", ")
      @body, @subject = get_body(email), email.subject

      # backward compatibility: there may be bad data in db
      @email_address = EmailAddress.where("user_id IS NOT NULL").where(:email => @from).first
      @email_address = EmailAddress.where(:email => @from).first unless @email_address
      @email_address = EmailAddress.create(:email => @from) unless @email_address

      @user = @email_address.user
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

  def receive(email)
    e = Mailman::Email.new(email)
    response_line =
      if e.body.blank?
        "the body of your email was blank or you didn't reply above the line."
      elsif too_large?(email)
        "you attached a file over #{MAX_ATTACHMENT_SIZE_HUMAN}"
      elsif too_old?(email)
        "your email was over a week old (or your clock is badly adjusted)."
      elsif bad_subject?(email)
        "the subject of your email was empty or it was too generic without providing a summary of the issue."
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

    e
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

  def bad_subject?(email)
    subject = email.subject
    subject.strip! unless subject.nil?
    return true if subject.blank?
    BAD_SUBJECTS.include?(subject)
  end

  def too_large?(email)
    email.attachments.detect { |file| file.body.to_s.size > MAX_ATTACHMENT_SIZE }
  end

  def too_old?(email)
    email.date < (Time.now - 1.week)
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

    task.updated_by_id= e.email_address.id
    task.save(validate: false)

    w = WorkLog.new(
      :user => e.user,
      :company => task.project.company,
      :project => task.project,
      :customer => task.project.customer,
      :email_address => e.email_address,
      :task => task,
      :started_at => Time.now.utc,
      :duration => 0,
      :body => e.body
    )
    w.save
    w.create_event_log(
      :user => e.user,
      :event_type => EventLog::TASK_COMMENT,
      :company => w.company,
      :project => w.project
    )

    send_changed_emails_for_task(w, files)
    Trigger.fire(task, Trigger::Event::UPDATED)
  end

  # Returns true if the email should be accepted
  def should_accept_email?(email, task)
    # for now, let's try just accepting everything
    return true
  end

  def save_attachments(e, email, task)
    email.attachments.reject! {|a| a.filename =~ /signature\.asc|smime\.p7s/}
    files = []
    if email.has_attachments?
      files = email.attachments.map do |attachment|
        add_attachment(e, task, attachment)
      end
    end
    return files.compact
  end

  def add_attachment(e, target, attachment)
    tempfile = File.open(Rails.root.join('tmp', attachment.filename.gsub(' ', '_').gsub(/[^a-zA-Z0-9_\.]/, '')), 'w')
    tempfile.write_nonblock(attachment.body)
    file= target.add_attachment(File.open(tempfile.path), e.user)
    File.delete(tempfile.path) rescue 0 # ignore deletion error
    return file
  end

  def create_task_from_email(e, email, project)
    task = Task.new(
      :name => email.subject,
      :project => project,
      :company => project.company,
      :description => e.body,
      :duration => 0,
      :updated_by_id=> e.email_address.id
    )

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
    work_log = WorkLog.create_task_created!(task, e.user)
    work_log.email_address= e.email_address
    work_log.save!
    work_log.notify
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
      unless task.company.suppressed_email_addresses.try(:include?, email.strip)
        # backward compatibility: there may be bad data in db
        ea = EmailAddress.where("user_id IS NOT NULL").where(:email => email.strip).first
        ea = EmailAddress.where(:email => email.strip).first unless ea
        ea = EmailAddress.create(:email => email.strip) unless ea
        task.email_addresses << ea
      end
    end
  end

  def attach_customers_to_task(task)
    task.users.each do |user|
      if user.customer and !task.customers.include?(user.customer)
        task.customers << user.customer unless user.customer.internal_customer?
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
      work_log.notify(files)
      user.receive_own_notifications=tmp
      user.save!
    else
      work_log.notify(files)
    end
  end

end
