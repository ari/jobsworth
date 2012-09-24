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
end
