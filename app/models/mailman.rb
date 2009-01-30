# Receive and handle emails sent to tasks

class Mailman < ActionMailer::Base

  def get_body(email)
      body = nil

      if email.multipart? then
        email.parts.each do |m|
          puts m.content_type
          if m.content_type.downcase == "text/plain"
            body = m.body
          elsif m.multipart?
            body = get_body(m)
          end
        end
      end

      body ||= email.body
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
#      Rails.logger "Looking for #{subdomain}.."
      company ||= Company.find_by_subdomain(subdomain)
    end

    if company
      e.company = company
      e.user = User.find_by_email(e.from, :conditions => ["company_id = ?", company.id])
    end

    e.save

#    return if(e.from.downcase.include? $CONFIG[:domain] || company.nil?)

    target = nil
    email.to.each do |to|
      if to.include?("task-")
#        Rails.logger "looking for a task"
        _, task_num = /task-(\d+).*@.*/.match(to).to_a
        if task_num.to_i > 0
#          Rails.logger "Looking for task[#{task_num}] from [#{company.name}]"
          target = Task.find(:first, :conditions => ["company_id = ? AND task_num = ?", company.id, task_num])
        end
      end
    end

    puts "target[#{target}]"

    if target && target.is_a?(Task)
      puts "Found target [#{target.name}]"
      notify_targets = target.project.users.collect{ |u| u.email.downcase }.flatten.uniq
      notify_targets += Task.find(:all, :conditions => ["project_id = ? AND notify_emails IS NOT NULL and notify_emails <> ''", target.project_id]).collect{ |t| t.notify_emails.split(',').collect{ |i| i.strip.downcase } }.flatten.uniq

#      Rails.logger "Possible participants[#{notify_targets.join(', ')}]"

      if notify_targets.include?(email.from.first.downcase)
        if email.has_attachments?
          email.attachments.each do |attachment|

#            Rails.logger "Attachement[#{attachment.original_filename}]"

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
            File.open(task_file.file_path, "wb", 0777) { |f| f.write( attachment.read ) } rescue begin
 #                                                                                         Rails.logger "Unable to save attachment.."
                                                                                          task_file.destroy
                                                                                          task_file = nil
                                                                                        end
            if task_file
              task_file.file_size = File.size(task_file.file_path)
  #            Rails.logger "Attachment saved[#{task_file.file_path}][#{task_file.file_size}]"
              task_file.save
            end

          end
        end

        w = WorkLog.new
        w.user = e.user
        w.company = target.project.company
        w.customer = target.project.customer
        w.project = target.project
        w.task = target
        w.started_at = Time.now.utc
        w.duration = 0
        w.log_type = EventLog::TASK_COMMENT
        w.body = e.body
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

        Notifications::deliver_changed( :comment, target, user, e.body.gsub(/<[^>]*>/,'')) rescue begin
#                                                                                                    Rails.logger "Error sending notificaiton email"
                                                                                                  end 
      else
        # Unknown email
        Notifications::deliver_unknown_from_address(email.from.first, company.subdomain) rescue nil
      end
    end

#      if email.has_attachments?
#        for attachment in email.attachments
#          page.attachments.create({
#            :file => attachment,
#            :description => email.subject
#          })
#        end
#      end
    end
  end
