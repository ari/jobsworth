# encoding: UTF-8
# Mail handlers for all notifications, except login / signup


class Notifications < ActionMailer::Base

  def created(task, user, _recipients_, note = "", files=[])
    @task, @user, @note, @_recipients_ = task, user, note, _recipients_
    files.each{|file|  attachments[file.file_file_name]= File.read(file.file_path)}
    mail(:to => _recipients_,
         :date => Time.now,
         :reply_to => "task-#{task.task_num}@#{user.company.subdomain}.#{$CONFIG[:email_domain]}",
         :subject => "#{$CONFIG[:prefix]} #{_('Created')}: #{task.issue_name} [#{task.project.name}] (#{(task.users.empty? ? _('Unassigned') : task.users.collect{|u| u.name}.join(', '))})"
         )
  end

  def changed(update_type, task, user, _recipients_, change, files=[])
    @task, @user, @change, @_recipients_ = task, user, change, _recipients_

    sub_ject = case update_type
               when EventLog::TASK_COMPLETED  then "#{$CONFIG[:prefix]} #{_'Resolved'}: #{task.issue_name} -> #{_(task.status_type)} [#{task.project.name}] (#{user.name})"
               when EventLog::TASK_MODIFIED    then "#{$CONFIG[:prefix]} #{_'Updated'}: #{task.issue_name} [#{task.project.name}] (#{user.name})"
               when EventLog::TASK_COMMENT    then "#{$CONFIG[:prefix]} #{_'Comment'}: #{task.issue_name} [#{task.project.name}] (#{user.name})"
               when EventLog::TASK_REVERTED   then "#{$CONFIG[:prefix]} #{_'Reverted'}: #{task.issue_name} [#{task.project.name}] (#{user.name})"
               when EventLog::TASK_ASSIGNED then "#{$CONFIG[:prefix]} #{_'Reassigned'}: #{task.issue_name} [#{task.project.name}] (#{task.owners_to_display})"
                 else
                   "#{$CONFIG[:prefix]} #{_'Comment'}: #{task.issue_name} [#{task.project.name}] (#{user.name})"
               end
    files.each{|file|  attachments[file.file_file_name]= File.read(file.file_path)}
    mail(:subject => sub_ject,
         :date => Time.now,
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

  def response_to_invalid_email(from, responce_string)
    @responce_string= responce_string
    mail(:subject => "#{$CONFIG[:prefix]} invalid email",
         :date => Time.now,
         :to => from)
  end

private

  def mail(headers={}, &block)
    headers[:from] = "#{$CONFIG[:from]}@#{$CONFIG[:email_domain]}" unless headers.has_key?(:from)
    super headers, &block
  end

end
