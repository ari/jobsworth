# encoding: UTF-8
module ScheduleHelper

  def link_to_gantt_task(task)
    link = "<strong>#{task.issue_num}</strong> "
    url = url_for(:id => task.task_num, :controller => 'tasks', :action => 'edit')
    title = task.to_tip(:duration_format => current_user.duration_format,
                        :workday_duration => current_user.workday_duration,
                        :days_per_week => current_user.days_per_week,
                        :user => current_user)
    link += link_to(truncate(task.name, :length => 70), url, {:class => "tasklink", :rel => "tooltip", :title => title})
    return link.html_safe
  end

end
