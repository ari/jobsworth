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
end
