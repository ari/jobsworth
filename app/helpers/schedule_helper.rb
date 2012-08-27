# encoding: UTF-8
module ScheduleHelper

  def link_to_gantt_task(task)
    link = "<strong>#{task.issue_num}</strong> "
    url = url_for(:id => task.task_num, :controller => 'tasks', :action => 'edit')
    title = task.to_tip(:user => current_user)
    link += link_to(truncate(task.name, :length => 70), url, {:class => "tasklink", :rel => "tooltip", :title => title})
    return link.html_safe
  end

end
