# encoding: UTF-8
# Receive and handle emails sent to tasks

class Mailman < ActionMailer::Base
  # The marker in the email body that shows where the new content ends
  BODY_SPLIT = "o------ please reply above this line ------o"

  def self.receive(mail)
    # fix invalid byte sequence in UTF-8
    # https://github.com/mikel/mail/issues/340
    mail.force_encoding("binary")

    super
  end

  ### Mailman::Email provides a way to extract content from incoming email
  class Email
    attr_accessor :from, :body, :subject, :user, :company, :email_address, :email

    def initialize(email)
      @from    =  email.from.first
      @body    =  Email.get_body(email)
      @subject =  email.subject
      @email   =  email

      # find company
      (email.to+Array.wrap(email.resent_to)).each do |to|
        next unless to.include?(Setting.domain)
        subdomain = to.split('@')[1].split('.')[0]
        @company ||= Company.find_by_subdomain(subdomain)
      end

      # if company not found but we're using a single company install, just use that one
      @company ||= Company.first if Company.count == 1

      # backward compatibility: there may be bad data in db
      @email_address = EmailAddress.where("user_id IS NOT NULL").where(:email => @from).first
      @email_address = EmailAddress.where(:email => @from).first unless @email_address
      @email_address = EmailAddress.create(:email => @from, :company => company) unless @email_address

      # find user
      @user = @email_address.user
    end

    def blank?
      @body.blank?
    end

    def bad_subject?
      @subject.strip! unless @subject.nil?
      return true if @subject.blank?
      BAD_SUBJECTS.include?(@subject)
    end

    def too_large?
      @email.attachments.detect { |file| file.body.to_s.size > MAX_ATTACHMENT_SIZE }
    end

    def too_old?
      @email.date < (Time.now - 1.week)
    end

    def self.get_body(email)
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
      body = Email.clean_body(body)
      return body
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
  end
  ### end Mailman::Email

  def receive(email)
    # create wrapper email object
    wrapper = Mailman::Email.new(email)

    # check invalid email
    response_line =
      if wrapper.blank?
        I18n.t("mailmans.wrapper.blank")
      elsif wrapper.too_large?
        I18n.t("mailmans.wrapper.too_large", max: MAX_ATTACHMENT_SIZE_HUMAN)
      elsif wrapper.too_old?
        I18n.t("mailmans.wrapper.too_old")
      elsif wrapper.bad_subject?
        I18n.t("mailmans.wrapper.bad_subject")
      end

    # if no company found
    if !wrapper.company
      response_line = I18n.t("mailmans.no_company")
    end

    if wrapper.user and !wrapper.user.active
      response_line = I18n.t("mailmans.inactive_user")
    end

    # find target
    target = target_for(email, wrapper.company)
    if !target
      response_line= I18n.t("mailmans.no_related")
    end

    if !response_line.nil?
      Notifications.response_to_invalid_email(email.from.first, response_line).deliver
      return false
    end

    if target.is_a?(TaskRecord)
      add_email_to_task(wrapper, target)
    elsif target.is_a?(Project)
      create_task_from_email(wrapper, target)
    end

    wrapper
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
          target = TaskRecord.where("company_id = ? AND task_num = ?", company.id, task_num).first
        end
      end
    end

    target ||= default_project(company) if company

    target
  end

  # Returns the default email project for company, or nil
  # if none.
  def default_project(company)
    id = company.preference("incoming_email_project")
    return company.projects.find_by_id(id)
  end

  def add_email_to_task(wrapper, task)
    files = save_attachments(wrapper, task)

    # if it's from unknown, add email to task email_addresses
    unless wrapper.user or task.email_addresses.include? wrapper.email_address
      task.email_addresses << wrapper.email_address
    end

    task.update_column(:updated_by_id, wrapper.email_address.id)
    task.touch

    work_log = WorkLog.create(
      :user => wrapper.user,
      :company => task.project.company,
      :project => task.project,
      :customer => task.project.customer,
      :email_address => wrapper.email_address,
      :task => task,
      :started_at => Time.now.utc,
      :duration => 0,
      :body => wrapper.body
    )

    if wrapper.user && wrapper.user.comment_private_by_default?
      work_log.update_column(:access_level_id,2)
    end

    work_log.create_event_log(
      :user => wrapper.user,
      :event_type => EventLog::TASK_COMMENT,
      :company => work_log.company,
      :project => work_log.project
    )

    notify_users(work_log, files)
    Trigger.fire(task, Trigger::Event::UPDATED)
  end

  def save_attachments(wrapper, task)
    wrapper.email.attachments.reject! {|a| a.filename =~ /signature\.asc|smime\.p7s/}
    files = []
    files = wrapper.email.attachments.map do |attachment|
      add_attachment(wrapper, task, attachment)
    end
    return files.compact
  end

  def add_attachment(wrapper, task, attachment)
    Dir.mkdir(Rails.root.join('tmp')) unless Dir.exist?(Rails.root.join('tmp'))
    tempfile = File.open(Rails.root.join('tmp', attachment.filename.gsub(' ', '_').gsub(/[^a-zA-Z0-9_\.]/, '')), 'w')
    tempfile.write_nonblock(attachment.body)
    file= task.add_attachment(File.open(tempfile.path), wrapper.user)
    File.delete(tempfile.path) rescue 0 # ignore deletion error
    return file
  end

  def create_task_from_email(wrapper, project)
    task = TaskRecord.new(
      :name => wrapper.subject,
      :project => project,
      :company => project.company,
      :description => wrapper.body,
      :duration => 0,
      :updated_by_id=> wrapper.email_address.id
    )

    task.set_default_properties
    begin
      task.save(:validate=>false)
    rescue ActiveRecord::RecordNotUnique
      task.save(:validate=>false)
    end

    attach_users_to_task(task, wrapper.email)
    attach_customers_to_task(task)
    files = save_attachments(wrapper, task)

    work_log = WorkLog.create_task_created!(task, wrapper.user)
    work_log.email_address = wrapper.email_address
    work_log.save!

    notify_users(work_log, files)
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
    elsif !task.company.suppressed_emails.include?(email.strip)
      # backward compatibility: there may be bad data in db
      ea = EmailAddress.where("user_id IS NOT NULL").where(:email => email.strip).first
      ea = EmailAddress.where(:email => email.strip).first unless ea
      ea = EmailAddress.create(:email => email.strip, :company => task.company) unless ea
      task.email_addresses << ea
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
    if task.customers.size.zero?
      task.customers << task.project.customer
    end
  end

  def notify_users(work_log, files)
    user = work_log.user
    tmp  = user.receive_own_notifications
    user.receive_own_notifications = false
    #skip save! if incoming email came from unknown user
    if user.new_record?
      work_log.notify(files)
    else
      user.update_column(:receive_own_notifications, false)
      work_log.notify(files)
      user.update_column(:receive_own_notifications, tmp)
    end
  end

end
