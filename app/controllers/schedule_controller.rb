# Generate a calendar showing completed and due Tasks for a Company
# TODO: Simple Events
class ScheduleController < ApplicationController

  def gantt
    @range = [Time.now.utc.midnight, 2.month.since.utc.midnight - 1.day]
    @tasks = current_task_filter.tasks_for_gantt(params)
    @groups = []
    @tasks.each do |task, idx|
      name = [ task.project.name ]
      name << task.milestone.name.strip if task.milestone_id.to_i > 0
      name = name.join("/<br/>")
      @groups << {:name => name, :pid => task.project_id, :mid => task.milestone_id}
    end
    @groups.uniq!      
  end

  def gantt_save
    t = Task.find_by_task_num(params[:id])
    t.duration = params[:duration].to_i * 480
    repeat = t.parse_repeat(params[:due_date])
    if repeat && repeat != ""
      t.repeat = repeat
      t.due_at = tz.local_to_utc(t.next_repeat_date)
    else
      t.repeat = nil
      due_date = DateTime.strptime(params[:due_date], current_user.date_format)
      t.due_at = tz.local_to_utc(due_date.to_time)
    end
    if current_user.can?(t.project, 'edit')
      body = ""
      if t.scheduled_at != t.due_at
        old_name = "None"
        old_name = current_user.tz.utc_to_local(t.due_at).strftime_localized("%A, %d %B %Y") unless t.due_at.nil?

        new_name = "None"
        new_name = current_user.tz.utc_to_local(t.scheduled_at).strftime_localized("%A, %d %B %Y") unless t.scheduled_at.nil?

        body << "- Due: #{old_name} -> #{new_name}\n"
        t.due_at = t.scheduled_at
      end
      if t.scheduled_duration.to_i != t.duration.to_i
        body << "- Estimate: #{worked_nice(t.duration).strip} -> #{worked_nice(t.scheduled_duration)}\n"
        t.duration = t.scheduled_duration
      end

      if body != ""
        worklog = WorkLog.new
        worklog.log_type = EventLog::TASK_MODIFIED
        worklog.user = current_user
        worklog.for_task(t)
        worklog.body = body
        worklog.save
      end

      t.scheduled_at = nil
      t.scheduled_duration = 0
      t.scheduled = false
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

end
