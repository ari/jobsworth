# Mail handlers for all notifications, except login / signup


class Notifications < ActionMailer::Base

  require  File.join(File.dirname(__FILE__), '../../lib/misc')
  self.default :from => "#{$CONFIG[:from]}@#{$CONFIG[:email_domain]}"
  def created(task, user, _recipients_, note = "", sent_at = Time.now)
    @task, @user, @note, @_recipients_ = task, user, note, _recipients_

    mail(:to => _recipients_,
         :date => sent_at,
         :reply_to => "task-#{task.task_num}@#{user.company.subdomain}.#{$CONFIG[:email_domain]}",
         :subject => "#{$CONFIG[:prefix]} #{_('Created')}: #{task.issue_name} [#{task.project.name}] (#{(task.users.empty? ? _('Unassigned') : task.users.collect{|u| u.name}.join(', '))})"
         )
  end

  def changed(update_type, task, user, _recipients_, change, sent_at = Time.now)
    @task, @user, @change, @_recipients_ = task, user, change, _recipients_

    sub_ject = case update_type
               when :completed  then "#{$CONFIG[:prefix]} #{_'Resolved'}: #{task.issue_name} -> #{_(task.status_type)} [#{task.project.name}] (#{user.name})"
               when :status     then "#{$CONFIG[:prefix]} #{_'Resolution'}: #{task.issue_name} -> #{_(task.status_type)} [#{task.project.name}] (#{user.name})"
               when :updated    then "#{$CONFIG[:prefix]} #{_'Updated'}: #{task.issue_name} [#{task.project.name}] (#{user.name})"
               when :comment    then "#{$CONFIG[:prefix]} #{_'Comment'}: #{task.issue_name} [#{task.project.name}] (#{user.name})"
               when :reverted   then "#{$CONFIG[:prefix]} #{_'Reverted'}: #{task.issue_name} [#{task.project.name}] (#{user.name})"
               when :reassigned then "#{$CONFIG[:prefix]} #{_'Reassigned'}: #{task.issue_name} [#{task.project.name}] (#{task.owners_to_display})"
               end

    mail(:subject => sub_ject,
         :date => sent_at,
         :to => _recipients_,
         :reply_to => "task-#{task.task_num}@#{user.company.subdomain}.#{$CONFIG[:email_domain]}"
         )
  end


  def reminder(tasks, tasks_tomorrow, tasks_overdue, user, sent_at = Time.now)
    @tasks, @tasks_tomorrow, @tasks_overdue, @user = tasks, tasks_tomorrow, tasks_overdue, user

    mail(:subject => "#{$CONFIG[:prefix]} #{_('Tasks due')}",
         :date => sent_at,
         :to => user.email,
         :reply_to => user.email
         )
  end

  def forum_reply(user, post, sent_at = Time.now)
    @user, @post = user, post

    mail(:subject => "#{$CONFIG[:prefix]} Reply to #{post.topic.title} [#{post.forum.name}]",
         :date => sent_at,
         :to => (post.topic.posts.collect{ |p| p.user.email if(p.user.receive_notifications > 0) } + post.topic.monitors.collect(&:email) + post.forum.monitors.collect(&:email) ).uniq.compact - [user.email],
         :reply_to => user.email
         )
  end

  def forum_post(user, post, sent_at = Time.now)
    @user, @post = user, post

    mail(:subject => "#{$CONFIG[:prefix]} New topic #{post.topic.title} [#{post.forum.name}]",
         :date => sent_at,
         :to => (post.topic.posts.collect{ |p| p.user.email if(p.user.receive_notifications > 0) } + post.forum.monitors.collect(&:email)).uniq.compact - [user.email],
         :reply_to => user.email
         )
  end

  def unknown_from_address(from, subdomain)
    @to, @subdomain = from, subdomain

    mail(:subject => "#{$CONFIG[:prefix]} Unknown email address: #{from}",
         :date => Time.now,
         :to => from
         )
  end

  def milestone_changed(user, milestone, action, due_date = nil, old_name = nil)
    @user, @milestone, @action, @due_date, @old_name  = user, milestone, action, due_date, old_name

    if old_name.nil?
      sub_ject    = "#{$CONFIG[:prefix]} #{_('Milestone')} #{action}: #{milestone.name} [#{milestone.project.customer.name} / #{milestone.project.name}]"
    else
      sub_ject    = "#{$CONFIG[:prefix]} #{_('Milestone')} #{action}: #{old_name} -> #{milestone.name} [#{milestone.project.customer.name} / #{milestone.project.name}]"
    end

    mail(:subject => sub_ject,
         :date => Time.now,
         :to => (milestone.project.users.collect{ |u| u.email if u.receive_notifications > 0 } ).uniq,
         :reply_to => user.email)
  end

end
