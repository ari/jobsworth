# Generate a calendar showing completed and due Tasks for a Company
# TODO: Simple Events
class ScheduleController < ApplicationController

  def list
    redirect_to :action => "gantt"
  end

  def gantt
  end

  def gantt_data
    @tasks = current_task_filter.tasks_for_gantt(params)
    @last_project_id = @tasks.collect(&:project_id).last
  end

  def gantt_save
    t = Task.find_by_task_num(params[:id])
    old_task_duration = t.duration
    old_task_due_at = t.due_at
    t.duration = parse_time("#{params[:duration]}d", true)
    repeat = t.parse_repeat(params[:due_date])
    if repeat && repeat != ""
      t.repeat = repeat
      t.due_at = tz.local_to_utc(t.next_repeat_date)
    else
      t.repeat = nil
      due_date = DateTime.strptime(params[:due_date], current_user.date_format)
      t.due_at = tz.local_to_utc(due_date.to_time)
    end
    t.scheduled_duration = t.duration if t.scheduled? && t.duration != old_task_duration
    t.scheduled_at = t.due_at if t.scheduled? && t.due_at != old_task_due_at
    if current_user.can?(t.project, 'edit')
      body = ""
      body << task_duration_changed(Task.find(t.id), t)
      body << task_due_changed(Task.find(t.id), t)
      if body != ""
        worklog = WorkLog.new
        worklog.log_type = EventLog::TASK_MODIFIED
        worklog.user = current_user
        worklog.for_task(t)
        worklog.body = body
        worklog.save
      end

      #t.scheduled_at = nil
      #t.scheduled_duration = 0
      #t.scheduled = false
      t.save
    end
    
    m = t.milestone 
    if current_user.can?(t.project, 'milestone') && m && !m.completed_at & m.scheduled
      if m.due_at != m.scheduled_at
        m.due_at = m.scheduled_at
      end
      m.scheduled_at = nil
      m.scheduled = false
      m.save
    end

    render :nothing => true
  end

  def gantt_milestone_save
    m = Milestone.find(params[:id])
    if current_user.can?(m.project, 'milestone')
      due_date = DateTime.strptime(params[:due_date], current_user.date_format)
      m.due_at = tz.local_to_utc(due_date.to_time)
      m.save
    end

    render :nothing => true
  end

  protected
  def task_due_changed(old_task, task)
    if old_task.due_at != task.due_at
      old_name = "None"
      old_name = current_user.tz.utc_to_local(old_task.due_at).strftime_localized("%A, %d %B %Y") unless old_task.due_at.nil?
      new_name = "None"
      new_name = current_user.tz.utc_to_local(task.due_at).strftime_localized("%A, %d %B %Y") unless task.due_at.nil?

      return  "- Due:".html_safe + " #{old_name} -> #{new_name}\n"
    else
      return ""
    end
  end

  def task_duration_changed(old_task, task)
    (old_task.duration != task.duration) ? "- Estimate: #{worked_nice(old_task.duration).strip} -> #{worked_nice(task.duration)}\n".html_safe : ""
  end

end
