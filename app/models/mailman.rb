# Receive and handle emails sent to tasks

class Mailman < ActionMailer::Base
  # The marker in the email body that shows where the new content ends
  BODY_SPLIT = "o------ please reply above this line ------o"

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

  def get_body(email)
    body = nil

    if email.multipart? then
      email.parts.each do |m|
        next if body

        if m.content_type =~ /text\/plain/i
          body = m.body.to_s
        elsif m.multipart?
          body = get_body(m)
        end
      end
    end

    body ||= email.body.to_s
    body = Mailman.clean_body(body)
    body = CGI::escapeHTML(body)
    return body
  end

  def receive(email)
    e = Email.new
    e.to = email.to.join(", ")
    e.from = email.from.join(", ")
    e.body = get_body(email)
    e.subject = email.subject

    company = nil
    email.to.each do |to|
      next unless to.include?($CONFIG[:domain])
      subdomain = to.split('@')[1].split('.')[0]
      company ||= Company.find_by_subdomain(subdomain)
    end
    # if company not found but we're using a single company install, just
    # use that one
    company ||= Company.first if Company.count == 1
    if company
      e.company = company
      e.user = User.find_by_email(e.from, :conditions => ["company_id = ?", company.id])
    end
    e.save

    target = target_for(email, company)
    if target and target.is_a?(Task)
      add_email_to_task(e, email, target)

    elsif target and target.is_a?(Project)
      task = create_task_from_email(email, target)
      add_email_to_task(e, email, task)

    else
      Notifications::deliver_unknown_from_address(email.from.first, company.subdomain)
    end

    return e
  end

  private

  # Returns the target location for the given email. Could be
  # a Task, a Project or nil.
  def target_for(email, company)
    target = nil
    email.to.each do |to|
      if to.include?("task-")
        _, task_num = /task-(\d+).*@.*/.match(to).to_a
        if task_num.to_i > 0
          target = Task.find(:first, :conditions =>
                             ["company_id = ? AND task_num = ?", company.id, task_num])
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

    if email.has_attachments?
      email.attachments.each do |attachment|
        add_attachment(e, task, attachment)
      end
    end

    if task.done?
      # need to reopen task so incoming comment doens't get closed
      task.update_attributes(:completed_at => nil,
                             :status => Task.status_types.index("Open"))
    end

    # worklogs need a user, so just use the first admin user if the email didn't give us one
    if e.user.nil?
      # TOFIX migrate admin column to boolean
      e.user = task.company.users.first(:conditions => { :admin => 1 })
      e.body += "\nEmail from: #{ e.from }"
    end

    w = WorkLog.new(:user => e.user, :company => task.project.company,
                    :customer => task.project.customer,
                    :task => task, :started_at => Time.now.utc,
                    :duration => 0, :log_type => EventLog::TASK_COMMENT,
                    :body => e.body)
    w.save

    w.event_log.user = e.user
    w.event_log.save

    send_changed_emails_for_task(w)
  end

  # Returns true if the email should be accepted
  def should_accept_email?(email, task)
    # for now, let's try just accepting everything
    return true

    # This is the old code:
#     notify_targets = task.project.users.map { |u| u.email }
#     notify_targets += Task.find(:all, :conditions => ["project_id = ? AND notify_emails IS NOT NULL and notify_emails <> ''", task.project_id]).collect{ |t| t.notify_emails.split(',')}.flatten.uniq
#     notify_targets = notify_targets.flatten.compact.uniq
#     notify_targets = notify_targets.map { |nt| nt.strip.downcase }
#     return  notify_targets.include?(email.from.first.downcase)
  end

  def add_attachment(e, target, attachment)
    task_file = ProjectFile.new()
    task_file.company = target.company
    task_file.customer = target.project.customer
    task_file.project = target.project
    task_file.task = target
    task_file.user = e.user
    task_file.file=attachment.body.to_s
    task_file.file_file_name=$1  unless (attachment.content_type =~ /name=([^;]*)/ ).nil?
    task_file.save
  end

  def create_task_from_email(email, project)
    task = Task.new(:name => email.subject,
                    :project => project,
                    :company => project.company,
                    :description => "",
                    :duration => 0)
    task.set_default_properties
    task.save(false)
    attach_users_to_task(task, email)
    task.save(false)
    attach_customers_to_task(task)

    # need to do without_validations to get around validation
    # errors on custom attributes
    task.save(false)
    send_email_to_creator(task, email)

    return task
  end

  def attach_users_to_task(task, email)
    project = task.project

    (email.from || []).each do |email_addr|
      user = project.company.users.find_by_email(email_addr.strip)
      task.watchers << user if user
    end
    (email.to || []).each do |email_addr|
      user = project.company.users.find_by_email(email_addr.strip)
      task.owners << user if user
    end
    (email.cc || []).each do |email_addr|
      user = project.company.users.find_by_email(email_addr.strip)
      task.watchers << user if user
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

  def send_email_to_creator(task, email)
    email_body = email.body.to_s.gsub(/<[^>]*>/,'')
    # need a user, so just use the first admin
    user = task.company.users.first(:conditions => { :admin => 1 })
    Notifications::deliver_created(task, user, email.from.first.strip, email_body)
    task.mark_as_unread(user)
  end

  def send_changed_emails_for_task(work_log)
    user = work_log.user
    tmp=user.receive_own_notifications
    user.receive_own_notifications=false
    user.save!

    work_log.send_notifications

    user.receive_own_notifications=tmp
    user.save!
  end
end
