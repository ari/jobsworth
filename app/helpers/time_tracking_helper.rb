module TimeTrackingHelper

  # Returns a link to pause/unpause the given task. If task is not
  # currently being worked on in the current sheet, returns nothing
  def pause_task_link(task)
    return if (@current_sheet.nil? or @current_sheet.task != task)

    if @current_sheet.paused?
      image = image_tag("time_resume.png", 
                        :title => _("Resume working on <b>%s</b>.", task.name), 
                        :class => "tooltip")
    else
      image = image_tag("time_pause.png", 
                        :title => _("Pause working on <b>%s</b>.", task.name), 
                        :class => "tooltip")
    end

    return link_to(image, :controller => "tasks", :action => "pause_work", :id => task)
  end

  # Returns a link to start or stop work on the given task.
  def start_stop_work_link(task)
    if @current_sheet and @current_sheet.task == task
      image = image_tag("time_add.png", :class => "tooltip work_icon", 
                        :title => _("Stop working on <b>%s</b>.", task.name))
      action = "stop_work"
    else
      image = image_tag("time.png", :class => "tooltip work_icon", 
                        :title => _("Start working on <b>%s</b>.", task.name))
      action = "start_work"
    end

    return link_to(image, :controller => "tasks", :action => action, :id => task.id)
  end

  # Returns a link to add work to the given task
  def add_work_link(task)
    image = image_tag("add.png", :class => "tooltip work_icon", 
                      :title => _("Add earlier work to <b>%s</b>.", task.name))

    return link_to(image, :controller => 'tasks', :action => 'add_work', :id => task)
  end

  # Returns a link to cancel the work on the given task
  def cancel_work_link(task)
    if @current_sheet and @current_sheet.task == task
      image = image_tag("time_delete.png", :class => "tooltip work_icon", 
                        :title => _("Cancel working on <b>%s</b>.", task.name))

      return link_to(image, { :controller => 'tasks', :action => "cancel_work", :id => task }, 
                     :confirm => "Really abort work?")
    end
  end


end
