# encoding: UTF-8
module MilestonesHelper
  def milestone_status_tag(milestone)
    css_class = case milestone.status_name
                when :planning then %w[label label-info]
                when :open     then %w[label label-success]
                when :locked   then %w[label label-warning]
                when :closed   then %w[label]
                end
    content_tag(:span,
                t(milestone.status_name, scope: 'milestones.statuses'),
                class: css_class).html_safe
  end

  def milestone_status_tip(status)
    status.present? ? t(status, scope: 'hint.milestone.statuses') : ''
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
    return " overdue_milestone"  if !m.due_at.nil? && m.due_at.utc < Time.now.utc
    ""
  end

  def link_to_milestone(milestone, options = {})
   options[:text] ||= milestone.name
   open = current_user.company.statuses.first
   link_to(options[:text], path_to_tasks_filtered_by(milestone, open),{
     :class => "#{milestone_classes(milestone)}",
     :rel => "popover",
     :title => milestone.name,
     "data-trigger" => "hover",
     "data-placement" => "right",
     "data-content" => milestone.to_tip(:user => current_user)} )
  end
end
