# encoding: UTF-8
# Mail handlers for all notifications, except login / signup


class Notifications < ActionMailer::Base

  def created(delivery)
    @task = delivery.work_log.task
    @user = delivery.work_log.user
    @recipient = delivery.email

    delivery.work_log.project_files.each{|file| attachments[file.file_file_name]= File.read(file.file_path)}

    previous_worklog = WorkLog.where("work_logs.task_id = ?", @task.id).joins(:email_deliveries).where("email_deliveries.id < ?", delivery.id).where("email_deliveries.email = ?", delivery.email).order("email_deliveries.id ASC").last

    if @task.work_logs.many?
      # an additional comment was added while creating this task
      @first_comment = @task.work_logs.last.body
    end

    fields = {
      :to => @recipient,
      "Message-ID"  => "<#{@task.task_num}.#{delivery.work_log.id}.jobsworth@#{Setting.domain}>",
      :date => delivery.work_log.started_at,
      :reply_to => "task-#{@task.task_num}@#{@user.company.subdomain}.#{Setting.email_domain}",
      :subject => "#{Setting.prefix} #{I18n.t("notifications.created")}: #{@task.issue_name} [#{@task.project.name}]"
    }
    fields["References"] = "<#{@task.task_num}.#{previous_worklog.id}.jobsworth@#{Setting.domain}>" if previous_worklog

    mail(fields)
  end

  def changed(delivery)
    @user = delivery.work_log.user
    @task = delivery.work_log.task
    @recipient = delivery.email
    @change = [delivery.work_log.user.name, delivery.work_log.body].join ":\n"

    s = case delivery.work_log.event_log.event_type
        when EventLog::TASK_COMPLETED  then "#{Setting.prefix} #{I18n.t("notifications.event_types.resolved")}: #{@task.issue_name} -> #{@task.human_value(:status)} [#{@task.project.name}]"
        when EventLog::TASK_MODIFIED    then "#{Setting.prefix} #{I18n.t("notifications.event_types.updated")}: #{@task.issue_name} [#{@task.project.name}]"
        when EventLog::TASK_COMMENT    then "#{Setting.prefix} #{I18n.t("notifications.event_types.comment")}: #{@task.issue_name} [#{@task.project.name}]"
        when EventLog::TASK_REVERTED   then "#{Setting.prefix} #{I18n.t("notifications.event_types.reverted")}: #{@task.issue_name} [#{@task.project.name}]"
        when EventLog::TASK_ASSIGNED then "#{Setting.prefix} #{I18n.t("notifications.event_types.reassigned")}: #{@task.issue_name} [#{@task.project.name}]"
        else "#{Setting.prefix} #{I18n.t("notifications.event_types.comment")}: #{@task.issue_name} [#{@task.project.name}]"
        end

    previous_worklog = WorkLog.where("work_logs.task_id = ?", @task.id).joins(:email_deliveries).where("email_deliveries.id < ?", delivery.id).where("email_deliveries.email = ?", delivery.email).order("email_deliveries.id ASC").last

    delivery.work_log.project_files.each{|file|  attachments[file.file_file_name]= File.read(file.file_path)}

    fields = {
      :to => @recipient,
      "Message-ID"  => "<#{@task.task_num}.#{delivery.work_log.id}.jobsworth@#{Setting.domain}>",
      :date => delivery.work_log.started_at,
      :reply_to => "task-#{@task.task_num}@#{@user.company.subdomain}.#{Setting.email_domain}",
      :subject => s
    }
    fields["References"] = "<#{@task.task_num}.#{previous_worklog.id}.jobsworth@#{Setting.domain}>" if previous_worklog

    mail(fields)
  end

  def reminder(tasks, tasks_tomorrow, tasks_overdue, user, sent_at = Time.now)
    @tasks, @tasks_tomorrow, @tasks_overdue, @user = tasks, tasks_tomorrow, tasks_overdue, user

    mail(:subject => "#{Setting.prefix} #{I18n.t("notifications.tasks_due")}",
         :date => sent_at,
         :to => user.email,
         :reply_to => user.email
         )
  end

  def response_to_invalid_email(from, response_line)
    @response_line= response_line
    mail(:subject => I18n.t("notifications.invalid_email", prefix: Setting.prefix),
         :date => Time.now,
         :to => from)
  end

private

  def mail(headers={}, &block)
    headers[:from] = "#{Setting.from}@#{Setting.email_domain}" unless headers.has_key?(:from)
    super headers, &block
  end

end
