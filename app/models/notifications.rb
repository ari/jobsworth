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
    @headers    = {'Reply-To' => user.email}
  end

  def changed(task, user, change, note = "", sent_at = Time.now)
    @subject    = "[ClockingIT] Updated: #{task.issue_name} (#{user.name})"
    @body       = {:task => task, :user => user, :change => change, :note => note}

    @recipients = ""
    @recipients = [user.email] if user.receive_notifications > 0
    @recipients += task.users.collect{ |u| u.email if u.receive_notifications > 0 } unless task.users.empty?
    @recipients += task.watchers.collect{|w| w.email if w.receive_notifications > 0}
    @recipients += task.notify_emails.split(',').collect{|e| e.strip} unless (task.notify_emails.nil? || task.notify_emails.length == 0)
    @recipients.uniq!

    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
    @headers    = {'Reply-To' => user.email}
  end

  def commented(task, user, note = "", sent_at = Time.now)
    @subject    = "[ClockingIT] Comment: #{task.issue_name} (#{user.name})"
    @body       = {:task => task, :user => user, :note => note}

    @recipients = ""
    @recipients = [user.email] if user.receive_notifications > 0
    @recipients += task.users.collect{ |u| u.email if u.receive_notifications > 0 } unless task.users.empty?
    @recipients += task.watchers.collect{|w| w.email if w.receive_notifications > 0}
    @recipients += task.notify_emails.split(',').collect{|e| e.strip} unless (task.notify_emails.nil? || task.notify_emails.length == 0)
    @recipients.uniq!

    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
    @headers    = {'Reply-To' => user.email}
  end

  def completed(task, user, note = "", sent_at = Time.now)
    @subject    = "[ClockingIT] Resolved: #{task.issue_name} (#{user.name})"
    @body       = {:task => task, :user => user, :note => note}

    @recipients = ""
    @recipients = [user.email] if user.receive_notifications > 0
    @recipients += task.users.collect{ |u| u.email if u.receive_notifications > 0 } unless task.users.empty?
    @recipients += task.watchers.collect{|w| w.email if w.receive_notifications > 0}
    @recipients += task.notify_emails.split(',').collect{|e| e.strip} unless (task.notify_emails.nil? || task.notify_emails.length == 0)
    @recipients.uniq!

    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
    @headers    = {'Reply-To' => user.email}
  end

  def reverted(task, user, note = "", sent_at = Time.now)
    @subject    = "[ClockingIT] Reverted #{task.issue_name} (#{user.name})"
    @body       = {:task => task, :user => user, :note => note}

    @recipients = ""
    @recipients = [user.email] if user.receive_notifications > 0
    @recipients += task.users.collect{ |u| u.email if u.receive_notifications > 0 } unless task.users.empty?
    @recipients += task.watchers.collect{|w| w.email if w.receive_notifications > 0}
    @recipients += task.notify_emails.split(',').collect{|e| e.strip} unless (task.notify_emails.nil? || task.notify_emails.length == 0)
    @recipients.uniq!

    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
    @headers    = {'Reply-To' => user.email}
  end

  def assigned(task, user, owners, old, note = "", sent_at = Time.now)
    @subject    = "[ClockingIT] Reassigned: #{task.issue_name} (#{(owners.empty? ? 'Unassigned' : owners.collect{ |u| u.name}.join(', ') )})"
    @body       = {:task => task, :user => user, :owners => owners, :note => note}

    @recipients = ""
    @recipients = [user.email] if user.receive_notifications > 0
    @recipients += owners.collect{ |u| u.email if u.receive_notifications > 0} unless owners.empty?
    @recipients += User.find(:all, :conditions => ["id IN (#{old})"]).collect{ |u| u.email if u.receive_notifications > 0} unless (old.nil? || old.empty?)
    @recipients += task.watchers.collect{|w| w.email if w.receive_notifications > 0}
    @recipients += task.notify_emails.split(',').collect{|e| e.strip} unless (task.notify_emails.nil? || task.notify_emails.length == 0)
    @recipients.uniq!

    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
    @headers    = {'Reply-To' => user.email}
  end

  def reminder(tasks, tasks_tomorrow, user, sent_at = Time.now)
    @body       = {:tasks => tasks, :tasks_tomorrow => tasks_tomorrow, :user => user}
    @subject    = "[ClockingIT] Tasks due"

    @recipients = [user.email]

    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
    @headers    = {'Reply-To' => user.email}
  end

  def forum_post(user, post, sent_at = Time.now)
    @body       = {:user => user, :post => post}
    @subject    = "[ClockingIT] Reply to #{post.topic.title}"

    @recipients = (post.topic.posts.collect{ |post| post.user.email if(post.user.receive_notifications > 0) } + post.topic.monitors.collect(&:email)).uniq - [user.email]

    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
    @headers    = {'Reply-To' => user.email}
  end

end
