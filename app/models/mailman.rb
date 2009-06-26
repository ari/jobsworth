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
    
    if company
      e.company = company
      e.user = User.find_by_email(e.from, :conditions => ["company_id = ?", company.id])
    end
    e.save

    target = target_for(email, company)
    if target && target.is_a?(Task)
      add_email_to_task(e, email, target)
    else
      # Unknown email
      begin
        Notifications::deliver_unknown_from_address(email.from.first, company.subdomain)
      rescue
        puts $!
      end
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
    notify_targets = task.project.users.collect{ |u| u.email.downcase }.flatten.uniq
    notify_targets += Task.find(:all, :conditions => ["project_id = ? AND notify_emails IS NOT NULL and notify_emails <> ''", task.project_id]).collect{ |t| t.notify_emails.split(',').collect{ |i| i.strip.downcase } }.flatten.uniq

    if notify_targets.include?(email.from.first.downcase)
      if email.has_attachments?
        email.attachments.each do |attachment|
          add_attachment(e, task, attachment)
        end
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
        
      recipients = task.users - [ e.user ]
      Notifications::deliver_changed(:comment, task, e.user, recipients,
                                     e.body.gsub(/<[^>]*>/,''))
    end
  end

  def add_attachment(e, target, attachment)
    task_file = ProjectFile.new()
    task_file.company = e.user.company
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

end
