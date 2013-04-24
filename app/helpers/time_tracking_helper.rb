# encoding: UTF-8
module TimeTrackingHelper

  # Returns a link to pause/unpause the given task. If task is not
  # currently being worked on in the current sheet, returns nothing
  def pause_task_link(task)
    return if (@current_sheet.nil? or @current_sheet.task != task)

    if @current_sheet.paused?
      image = image_tag("time_resume.png", "data-placement" => :right,
                        :title => t('timetracking.resume', task: escape_twice(task.name)),
                        :rel => "tooltip")
    else
      image = image_tag("time_pause.png", "data-placement" => :right,
                        :title => t('timetracking.pause', task: escape_twice(task.name)),
                        :rel => "tooltip")
    end

    return link_to(image, pause_work_index_path)
  end

  def pin_link(task)
    image = image_tag('pin-18x18.png', id: 'pin-btn')

    link_to image, start_work_index_path(task_num: task.task_num)
  end

  # Returns a link to start or stop work on the given task.
  def start_stop_work_link(task)
    # don't show link if working on another task already
    return if (@current_sheet and @current_sheet.task != task)

    if @current_sheet and @current_sheet.task == task
      image = image_tag("time_add.png", :class => "work_icon", :rel => "tooltip", "data-placement" => :right,
                        :title => t('timetracking.stop', task: escape_twice(task.name)))
      url = stop_work_index_path
    else
      image = image_tag("time.png", :class => "work_icon", :rel => "tooltip", "data-placement" => :right,
                        :title => t('timetracking.start', task: escape_twice(task.name)))
      url = start_work_index_path(:task_num => task.task_num)
    end

    return link_to(image, url)
  end

  # Returns a link to add work to the given task
  def add_work_link(task, text = nil)
    text ||= image_tag("add.png", :class => "work_icon", :rel => "tooltip", "data-placement" => :right,
                       :title => t('timetracking.add_earlier', task: escape_twice(task.name)))

    url = new_work_log_path(:task_id => task.task_num)
    return link_to(text, url)
  end

  # Returns a link to cancel the work on the given task
  def cancel_work_link(task)
    if @current_sheet and @current_sheet.task == task
      image = image_tag("time_delete.png", :class => "work_icon", :rel => "tooltip", "data-placement" => :right,
                        :title => t('timetracking.cancel', task: escape_twice(task.name)))

      return link_to(image, cancel_work_index_path, :confirm => t('timetracking.cancel_confirm'))
    end
  end

  def escape_twice(attr)
    h(String.new(h attr))
  end

end
