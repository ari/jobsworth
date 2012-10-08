# encoding: UTF-8
module MilestonesHelper
  def milestone_status_tag(milestone)
    case milestone.status_name
    when :planning
      %q[<span class="label label-info">planning</span>].html_safe
    when :open
      %q[<span class="label label-success">open</span>].html_safe
    when :locked
      %q[<span class="label label-warning">locked</span>].html_safe
    when :closed
      %q[<span class="label">closed</span>].html_safe
    end
  end

  def milestone_status_tip(status)
    return "" if status.nil?

    case status
    when :planning
      "planning(can add tasks, all tasks are snoozed)"
    when :open
      "open(can add tasks, tasks not snoozed)"
    when :locked
      "locked(cannot add tasks, tasks not snoozed)"
    when :closed
      "closed(cannot add tasks, all tasks are closed)"
    end
  end

  def milestone_status_select_tag(milestone)
    options = Milestone::STATUSES.each_with_index.map {|status, index|[status, index]}.reject {|p| p[0] == :closed}.collect do |pair|
      selected = if pair[0] == milestone.status_name then "selected=\"selected\"" else "" end
      "<option value=\"#{pair[1]}\" #{selected} title=\"#{milestone_status_tip(pair[0])}\">#{pair[0].to_s}</option>"
    end

    return select_tag("milestone[status]", options.join(' ').html_safe)
  end

  def milestone_classes(m)
    return " complete_milestone" unless m.completed_at.nil?

    unless m.due_at.nil?
      if m.due_at.utc < Time.now.utc
        return " overdue_milestone"
      end
    end
    ""
  end

  def link_to_milestone(milestone, options = {})
   options[:text] ||= milestone.name
   open= current_user.company.statuses.first
   link_to(options[:text], path_to_tasks_filtered_by(milestone, open),{
     :class => "#{milestone_classes(milestone)}",
     :rel => "popover",
     :title => milestone.name,
     "data-trigger" => "hover",
     "data-placement" => "right",
     "data-content" => milestone.to_tip(:user => current_user)} )
  end
end
