# encoding: UTF-8
# Mail handlers for all notifications, except login / signup


class Notifications < ActionMailer::Base

  def created(delivery)
    @task = delivery.work_log.task
    @user = delivery.work_log.user
    @recipient = delivery.email

    delivery.work_log.project_files.each{|file| attachments[file.file_file_name]= File.read(file.file_path)}

    mail(:to => @recipient,
         :date => delivery.work_log.started_at,
         :reply_to => "task-#{@task.task_num}@#{@user.company.subdomain}.#{$CONFIG[:email_domain]}",
         :subject => "#{$CONFIG[:prefix]} #{_('Created')}: #{@task.issue_name} [#{@task.project.name}]"
         )
  end

  def changed(delivery)
    @user = delivery.work_log.user
    @task = delivery.work_log.task
    @recipient = delivery.email
    @change = delivery.work_log.user.name + ":\n" + delivery.work_log.body

    s = case delivery.work_log.log_type
        when EventLog::TASK_COMPLETED  then "#{$CONFIG[:prefix]} #{_'Resolved'}: #{@task.issue_name} -> #{_(@task.status_type)} [#{@task.project.name}]"
        when EventLog::TASK_MODIFIED    then "#{$CONFIG[:prefix]} #{_'Updated'}: #{@task.issue_name} [#{@task.project.name}]"
        when EventLog::TASK_COMMENT    then "#{$CONFIG[:prefix]} #{_'Comment'}: #{@task.issue_name} [#{@task.project.name}]"
        when EventLog::TASK_REVERTED   then "#{$CONFIG[:prefix]} #{_'Reverted'}: #{@task.issue_name} [#{@task.project.name}]"
        when EventLog::TASK_ASSIGNED then "#{$CONFIG[:prefix]} #{_'Reassigned'}: #{@task.issue_name} [#{@task.project.name}]"
        else "#{$CONFIG[:prefix]} #{_'Comment'}: #{@task.issue_name} [#{@task.project.name}]"
        end

    delivery.work_log.project_files.each{|file|  attachments[file.file_file_name]= File.read(file.file_path)}
    mail(:to => @recipient,
         :date => delivery.work_log.started_at,
         :reply_to => "task-#{@task.task_num}@#{@user.company.subdomain}.#{$CONFIG[:email_domain]}",
         :subject => s
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

  def response_to_invalid_email(from, response_string)
    @responce_string= response_string
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
