module TimeTrackingHelper

  # Returns a link to pause/unpause the given task. If task is not
  # currently being worked on in the current sheet, returns nothing
  def pause_task_link(task)
    return if (@current_sheet.nil? or @current_sheet.task != task)

    if @current_sheet.paused?
      image = image_tag("time_resume.png", 
                        :title => _("Resume working on <b>%s</b>.", escape_twice(task.name)),
                        :class => "tooltip")
    else
      image = image_tag("time_pause.png", 
                        :title => _("Pause working on <b>%s</b>.", escape_twice(task.name)),
                        :class => "tooltip")
    end

    return link_to(image, pause_work_path)
  end

  # Returns a link to start or stop work on the given task.
  def start_stop_work_link(task)
    # don't show link if working on another task already
    return if (@current_sheet and @current_sheet.task != task)

    if @current_sheet and @current_sheet.task == task
      image = image_tag("time_add.png", :class => "tooltip work_icon", 
                        :title => _("Stop working on <b>%s</b>.", escape_twice(task.name)))
      url = stop_work_path
    else
      image = image_tag("time.png", :class => "tooltip work_icon", 
                        :title => _("Start working on <b>%s</b>.", escape_twice(task.name)))
      url = start_work_path(:task_num => task.task_num)
    end

    return link_to(image, url)
  end

  # Returns a link to add work to the given task
  def add_work_link(task, text = nil)
    text ||= image_tag("add.png", :class => "tooltip work_icon", 
                       :title => _("Add earlier work to <b>%s</b>.", escape_twice(task.name)))

    url = new_work_log_path(:task_id => task.task_num, 
                            :work_log => { :log_type => EventLog::TASK_WORK_ADDED })
    return link_to(text, url)
  end

  # Returns a link to cancel the work on the given task
  def cancel_work_link(task)
    if @current_sheet and @current_sheet.task == task
      image = image_tag("time_delete.png", :class => "tooltip work_icon", 
                        :title => _("Cancel working on <b>%s</b>.", escape_twice(task.name)))

      return link_to(image, cancel_work_path, :confirm => "Really abort work?")
    end
  end
  def escape_twice(attr)
    h(String.new(h attr))
  end
    

end
