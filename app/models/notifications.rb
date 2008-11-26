# Mail handlers for all notifications, except login / signup


class Notifications < ActionMailer::Base

  require  File.join(File.dirname(__FILE__), '../../lib/misc')

  def created(task, user, note = "", sent_at = Time.now)
    @body       = {:task => task, :user => user, :note => note}
    @subject    = "#{$CONFIG[:prefix]} #{_('Created')}: #{task.issue_name} [#{task.project.name}] (#{(task.users.empty? ? _('Unassigned') : task.users.collect{|u| u.name}.join(', '))})"

    @recipients = ""
    @recipients = [user.email] if user.receive_notifications > 0
    @recipients += task.users.collect{ |u| u.email if u.receive_notifications > 0 } unless task.users.empty?
    @recipients += task.watchers.collect{|w| w.email if w.receive_notifications > 0}
    @recipients += task.notify_emails.split(',').collect{|e| e.strip} unless (task.notify_emails.nil? || task.notify_emails.length == 0)
    @recipients.uniq!

    @from       = "#{$CONFIG[:from]}@#{$CONFIG[:email_domain]}"
    @sent_on    = sent_at
    @reply_to   = "task-#{task.task_num}@#{user.company.subdomain}.#{$CONFIG[:email_domain]}"
  end

  def changed(update_type, task, user, change, sent_at = Time.now)
    @subject = case update_type
               when :completed  then "#{$CONFIG[:prefix]} #{_'Resolved'}: #{task.issue_name} -> #{_(task.status_type)} [#{task.project.name}] (#{user.name})"
               when :status     then "#{$CONFIG[:prefix]} #{_'Status'}: #{task.issue_name} -> #{_(task.status_type)} [#{task.project.name}] (#{user.name})"
               when :updated    then "#{$CONFIG[:prefix]} #{_'Updated'}: #{task.issue_name} [#{task.project.name}] (#{user.name})"
               when :comment    then "#{$CONFIG[:prefix]} #{_'Comment'}: #{task.issue_name} [#{task.project.name}] (#{user.name})"
               when :reverted   then "#{$CONFIG[:prefix]} #{_'Reverted'}: #{task.issue_name} [#{task.project.name}] (#{user.name})"
               when :reassigned then "#{$CONFIG[:prefix]} #{_'Reassigned'}: #{task.issue_name} [#{task.project.name}] (#{task.owners})"
               end

    @body       = {:task => task, :user => user, :change => change}

    @recipients = ""
    @recipients = [user.email] if user.receive_notifications > 0
    @recipients += [task.creator.email] if task.creator && task.creator.receive_notifications > 0 
    @recipients += task.users.collect{ |u| u.email if u.receive_notifications > 0 } unless task.users.empty?
    @recipients += task.watchers.collect{|w| w.email if w.receive_notifications > 0}
    @recipients += task.notify_emails.split(',').collect{|e| e.strip} unless (task.notify_emails.nil? || task.notify_emails.length == 0)
    @recipients.uniq!

    @from       = "#{$CONFIG[:from]}@#{$CONFIG[:email_domain]}"
    @sent_on    = sent_at
    @reply_to   = "task-#{task.task_num}@#{user.company.subdomain}.#{$CONFIG[:email_domain]}"
  end


  def reminder(tasks, tasks_tomorrow, tasks_overdue, user, sent_at = Time.now)
    @body       = {:tasks => tasks, :tasks_tomorrow => tasks_tomorrow, :tasks_overdue => tasks_overdue, :user => user}
    @subject    = "#{$CONFIG[:prefix]} #{_('Tasks due')}"

    @recipients = [user.email]

    @from       = "#{$CONFIG[:from]}@#{$CONFIG[:email_domain]}"
    @sent_on    = sent_at
    @reply_to   = user.email
  end

  def forum_reply(user, post, sent_at = Time.now)
    @body       = {:user => user, :post => post}
    @subject    = "#{$CONFIG[:prefix]} Reply to #{post.topic.title} [#{post.forum.name}]"

    @recipients = (post.topic.posts.collect{ |p| p.user.email if(p.user.receive_notifications > 0) } + post.topic.monitors.collect(&:email) + post.forum.monitors.collect(&:email) ).uniq.compact - [user.email]

    @from       = "#{$CONFIG[:from]}@#{$CONFIG[:email_domain]}"
    @sent_on    = sent_at
    @reply_to   = user.email
  end

  def forum_post(user, post, sent_at = Time.now)
    @body       = {:user => user, :post => post}
    @subject    = "#{$CONFIG[:prefix]} New topic #{post.topic.title} [#{post.forum.name}]"

    @recipients = (post.topic.posts.collect{ |p| p.user.email if(p.user.receive_notifications > 0) } + post.forum.monitors.collect(&:email)).uniq.compact - [user.email]

    @from       = "#{$CONFIG[:from]}@#{$CONFIG[:email_domain]}"
    @sent_on    = sent_at
    @reply_to   = user.email
  end

  def chat_invitation(user, target, room)
    @body       = {:user => user, :room => room }
    @subject    = "#{$CONFIG[:prefix]} Invitation to chat: #{room.name} (#{user.name})"

    @recipients = target.email

    @from       = "#{$CONFIG[:from]}@#{$CONFIG[:email_domain]}"
    @sent_on    = Time.now
    @reply_to   = user.email

  end

  def unknown_from_address(from, subdomain)
    @body       = {:from => from, :subdomain => subdomain }
    @subject    = "#{$CONFIG[:prefix]} Unknown email address: #{from}"

    @recipients = from

    @from       = "noreply@#{$CONFIG[:email_domain]}"
    @sent_on    = Time.now
  end

  def milestone_changed(user, milestone, action, due_date = nil, old_name = nil)
    @body       = { :user => user, :milestone => milestone, :action => action, :due_date => due_date, :old_name => old_name }
    if old_name.nil?
      @subject    = "#{$CONFIG[:prefix]} #{_('Milestone')} #{action}: #{milestone.name} [#{milestone.project.customer.name} / #{milestone.project.name}]"
    else 
      @subject    = "#{$CONFIG[:prefix]} #{_('Milestone')} #{action}: #{old_name} -> #{milestone.name} [#{milestone.project.customer.name} / #{milestone.project.name}]"
    end
    @recipients = (milestone.project.users.collect{ |u| u.email if u.receive_notifications > 0 } ).uniq
    @sent_on    = Time.now
    @reply_to   = user.email
    @from       = "#{$CONFIG[:prefix]} Notification <noreply@#{$CONFIG[:email_domain]}>"
  end

end
