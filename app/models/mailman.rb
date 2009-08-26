# Receive and handle emails sent to tasks

class Mailman < ActionMailer::Base
  # The marker in the email body that shows where the new content ends
  BODY_SPLIT = "o------ please reply above this line ------o"

  def get_body(email)
    body = nil
    
    if email.multipart? then
      email.parts.each do |m|
        next if body

        if m.content_type.downcase == "text/plain"
          body = m.body
        elsif m.multipart?
          body = get_body(m)
        end
      end
    end
    
    body ||= email.body
    new_body_end = body.index(Mailman::BODY_SPLIT) || body.length
    return body[0, new_body_end].strip
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
    
    # worklogs need a user, so just use the first admin user if the
    # email didn't give us one
    if e.user.nil?
      e.user = task.company.users.first(:conditions => { :admin => true })
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
    
    user = nil
    if e.user.nil?
      user = User.new
      user.name = email.from.first
      user.email = email.from.first
      user.receive_notifications = 1
    else
      user = e.user
    end
    

    send_changed_emails_for_task(e, task, user)
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
    task_file.filename = attachment.original_filename
    task_file.name = attachment.original_filename
    task_file.file_size = 0
    task_file.save
    
    task_file.reload
    
    if !File.directory?(task_file.path)
      File.umask(0)
      Dir.mkdir(task_file.path, 0777) rescue nil
    end
    
    File.umask(0)
    begin
      File.open(task_file.file_path, "wb", 0777) { |f| f.write( attachment.read ) } 
    rescue 
      task_file.destroy
      task_file = nil
    end
    
    if task_file
      task_file.file_size = File.size(task_file.file_path)
      task_file.save
    end
  end

  def create_task_from_email(email, project)
    task = Task.new(:name => email.subject, 
                    :project => project,
                    :company => project.company,
                    :description => "",
                    :duration => 0) 
    task.set_task_num(project.company.id)

    (email.to || []).each do |email_addr|
      user = project.company.users.find_by_email(email_addr.strip)
      task.users << user if user
    end
    (email.cc || []).each do |email_addr|
      user = project.company.users.find_by_email(email_addr.strip)
      task.watchers << user if user
    end
#    task.watchers << email.user if email.user

    # need to do without_validations to get around validation
    # errors on custom attributes
    task.save(false)

    return task
  end

  def send_changed_emails_for_task(e, task, user)
    email_body = e.body.gsub(/<[^>]*>/,'')

    sent = []
    task.task_owners.each do |n|
      if n.notified_last_change? and n.user != user
        Notifications::deliver_changed(:comment, task, e.user, n.user.email, email_body)
        sent << n.user
      end
    end
    task.notifications.each do |n|
      if n.notified_last_change? and n.user != user
        Notifications::deliver_changed(:comment, task, e.user, n.user.email, email_body)
        sent << n.user
      end
    end
    
    (task.notify_emails || "").split(",").each do |email|
      if email != user.email
        Notifications::deliver_changed(:comment, task, e.user, email.strip, email_body)
      end
    end

    task.mark_as_notified_last_change(sent)
    task.mark_as_unread(user)
  end

end
