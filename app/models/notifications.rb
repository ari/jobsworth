class Notifications < ActionMailer::Base

  def created(task, user, note = "", sent_at = Time.now)
    @body       = {:task => task, :user => user, :note => note}
    @subject    = "[ClockingIT] Created: #{task.issue_name} (#{(task.users.empty? ? 'Unassigned' : task.users.collect{|u| u.name}.join(', '))})"

    @recipients = ""
    @recipients = [user.email] if user.receive_notifications > 0
    @recipients += task.users.collect{ |u| u.email if u.receive_notifications > 0 } unless task.users.empty?
    @recipients += task.watchers.collect{|w| w.email if w.receive_notifications > 0}
    @recipients += task.notify_emails.split(',').collect{|e| e.strip} unless (task.notify_emails.nil? || task.notify_emails.length == 0)
    @recipients.uniq!

    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
    @headers    = {'Reply-To' => "task-#{task.task_num}@#{user.company.subdomain}.#{$CONFIG[:domain]}"}
  end

  def changed(update_type, task, user, change, sent_at = Time.now)
    @subject = case update_type
               when :completed  : "[ClockingIT] #{_'Resolved'}: #{task.issue_name} -> #{_(task.status_type)} (#{user.name})"
               when :status     : "[ClockingIT] #{_'Status'}: #{task.issue_name} -> #{_(task.status_type)} (#{user.name})"
               when :updated    : "[ClockingIT] #{_'Updated'}: #{task.issue_name} (#{user.name})"
               when :comment    : "[ClockingIT] #{_'Comment'}: #{task.issue_name} (#{user.name})"
               when :reverted   : "[ClockingIT] #{_'Reverted'}: #{task.issue_name} (#{user.name})"
               when :reassigned : "[ClockingIT] #{_'Reassigned'}: #{task.issue_name} (#{task.owners})"
               end

    @body       = {:task => task, :user => user, :change => change}

    @recipients = ""
    @recipients = [user.email] if user.receive_notifications > 0
    @recipients += task.users.collect{ |u| u.email if u.receive_notifications > 0 } unless task.users.empty?
    @recipients += task.watchers.collect{|w| w.email if w.receive_notifications > 0}
    @recipients += task.notify_emails.split(',').collect{|e| e.strip} unless (task.notify_emails.nil? || task.notify_emails.length == 0)
    @recipients.uniq!

    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
    @headers    = {'Reply-To' => "task-#{task.task_num}@#{user.company.subdomain}.#{$CONFIG[:domain]}"}
  end

  def commented(task, user, note = "", sent_at = Time.now)
    @body       = {:task => task, :user => user, :note => note}

    @subject    = "[ClockingIT] #{_'Comment'}: #{task.issue_name} (#{user.name})"

    @recipients = ""
    @recipients = [user.email] if user.receive_notifications > 0
    @recipients += task.users.collect{ |u| u.email if u.receive_notifications > 0 } unless task.users.empty?
    @recipients += task.watchers.collect{|w| w.email if w.receive_notifications > 0}
    @recipients += task.notify_emails.split(',').collect{|e| e.strip} unless (task.notify_emails.nil? || task.notify_emails.length == 0)
    @recipients.uniq!

    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
    @headers    = {'Reply-To' => "task-#{task.task_num}@#{user.company.subdomain}.#{$CONFIG[:domain]}"}
  end

  def completed(task, user, note = "", sent_at = Time.now)
    @body       = {:task => task, :user => user, :note => note}

    @subject    = "[ClockingIT] #{_'Resolved'}: #{task.issue_name} -> #{_(task.status_type)} (#{user.name})"

    @recipients = ""
    @recipients = [user.email] if user.receive_notifications > 0
    @recipients += task.users.collect{ |u| u.email if u.receive_notifications > 0 } unless task.users.empty?
    @recipients += task.watchers.collect{|w| w.email if w.receive_notifications > 0}
    @recipients += task.notify_emails.split(',').collect{|e| e.strip} unless (task.notify_emails.nil? || task.notify_emails.length == 0)
    @recipients.uniq!

    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
    @headers    = {'Reply-To' => "task-#{task.task_num}@#{user.company.subdomain}.#{$CONFIG[:domain]}"}
  end

  def reverted(task, user, note = "", sent_at = Time.now)
    @body       = {:task => task, :user => user, :note => note}

    @subject    = "[ClockingIT] #{_'Reverted'}: #{task.issue_name} (#{user.name})"

    @recipients = ""
    @recipients = [user.email] if user.receive_notifications > 0
    @recipients += task.users.collect{ |u| u.email if u.receive_notifications > 0 } unless task.users.empty?
    @recipients += task.watchers.collect{|w| w.email if w.receive_notifications > 0}
    @recipients += task.notify_emails.split(',').collect{|e| e.strip} unless (task.notify_emails.nil? || task.notify_emails.length == 0)
    @recipients.uniq!

    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
    @headers    = {'Reply-To' => "task-#{task.task_num}@#{user.company.subdomain}.#{$CONFIG[:domain]}"}
  end

  def assigned(task, user, owners, old, note = "", sent_at = Time.now)
    @body       = {:task => task, :user => user, :owners => owners, :note => note}

    @subject    = "[ClockingIT] #{_'Reassigned'}: #{task.issue_name} (#{task.owners})"

    @recipients = ""
    @recipients = [user.email] if user.receive_notifications > 0
    @recipients += owners.collect{ |u| u.email if u.receive_notifications > 0} unless owners.empty?
    @recipients += User.find(:all, :conditions => ["id IN (#{old})"]).collect{ |u| u.email if u.receive_notifications > 0} unless (old.nil? || old.empty?)
    @recipients += task.watchers.collect{|w| w.email if w.receive_notifications > 0}
    @recipients += task.notify_emails.split(',').collect{|e| e.strip} unless (task.notify_emails.nil? || task.notify_emails.length == 0)
    @recipients.uniq!

    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
    @headers    = {'Reply-To' => "task-#{task.task_num}@#{user.company.subdomain}.#{$CONFIG[:domain]}"}
  end

  def reminder(tasks, tasks_tomorrow, tasks_overdue, user, sent_at = Time.now)
    @body       = {:tasks => tasks, :tasks_tomorrow => tasks_tomorrow, :tasks_overdue => tasks_overdue, :user => user}
    @subject    = "[ClockingIT] Tasks due"

    @recipients = [user.email]

    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
    @headers    = {'Reply-To' => user.email}
  end

  def forum_reply(user, post, sent_at = Time.now)
    @body       = {:user => user, :post => post}
    @subject    = "[ClockingIT] Reply to #{post.topic.title}"

    @recipients = (post.topic.posts.collect{ |post| post.user.email if(post.user.receive_notifications > 0) } + post.topic.monitors.collect(&:email) + post.forum.monitors.collect(&:email) ).uniq - [user.email]

    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
    @headers    = {'Reply-To' => user.email}
  end

  def forum_post(user, post, sent_at = Time.now)
    @body       = {:user => user, :post => post}
    @subject    = "[ClockingIT] New topic in #{post.forum.name}"

    @recipients = (post.topic.posts.collect{ |post| post.user.email if(post.user.receive_notifications > 0) } + post.forum.monitors.collect(&:email)).uniq - [user.email]

    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
    @headers    = {'Reply-To' => user.email}
  end

  def chat_invitation(user, target, room)
    @body       = {:user => user, :room => room }
    @subject    = "[ClockingIT] Invitation to chat: #{room.name} (#{user.name})"

    @recipients = target.email

    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = Time.now
    @headers    = {'Reply-To' => user.email}

  end

  def unknown_from_address(from, subdomain)
    @body       = {:from => from, :subdomain => subdomain }
    @subject    = "[ClockingIT] Unknown email address: #{from}"

    @recipients = from

    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = Time.now
  end

  def milestone_changed(user, milestone, action, due_date = nil, old_name = nil)
    @body       = { :user => user, :milestone => milestone, :action => action, :due_date => due_date, :old_name => old_name }
    if old_name.nil?
      @subject    = "[ClockingIT] Milestone #{action}: #{milestone.name} [#{milestone.project.name}]"
    else 
      @subject    = "[ClockingIT] Milestone #{action}: #{old_name} -> #{milestone.name} [#{milestone.project.name}]"
    end
    @recipients = (milestone.project.users.collect{ |u| u.email if u.receive_notifications > 0 } ).uniq
    @sent_on    = Time.now
    @headers    = {'Reply-To' => user.email}
    @from       = "ClockingIT Notification <noreply@#{$CONFIG[:domain]}>"
  end

end
