# encoding: UTF-8
module TasksHelper
  def render_task_form(show_timer = true)
    render partial: 'tasks/form', locals: { show_timer: show_timer }
  end

  def render_task_dependants(t, depth, root_present)
    res = ""
    @printed_ids ||= []

    return if @printed_ids.include? t.id

    shown = task_shown?(t)

    @deps = []

    if session[:hide_dependencies].to_i == 1
      res << render(:partial => "task_row", :locals => { :task => t, :depth => depth})
    else
      unless root_present
        root = nil
        parents = []
        p = t
        while(!p.nil? && p.dependencies.size > 0)
          root = nil
          p.dependencies.each do |dep|
            root = dep if((!dep.done?) && (!@deps.include?(dep.id) ) )
          end
          root ||= p.dependencies.first if(p.dependencies.first.id != p.id && !@deps.include?(p.dependencies.first.id))
          p = root
          @deps << root.id
        end
        res << render_task_dependants(root, depth, true) unless root.nil?
      else
        res << render(:partial => "task_row", :locals => { :task => t, :depth => depth, :override_filter => !shown }) if( ((!t.done?) && t.dependants.size > 0) || shown)

        @printed_ids << t.id

        if t.dependants.size > 0
          t.dependants.each do |child|
            next if @printed_ids.include? child.id
            res << render_task_dependants(child, (((!t.done?) && t.dependants.size > 0) || shown) ? (depth == 0 ? depth + 2 : depth + 1) : depth, true )
          end
        end
      end
    end
    res
  end

  ###
  # Returns the html to display a select field to set the tasks
  # milestone. The current milestone (if set) will be selected.
  ###
  def milestone_select(perms)
    milestones = Milestone.not_completed.
                  order('due_at, name').
                  where('company_id = ? AND project_id = ?', 
                    current_user.company.id, selected_project).
                  to_a
    
    if @task.has_milestone? and @task.milestone.complete?
      milestones << @task.milestone
    end

    milestones_to_select_tag(milestones)
  end

  ###
  # Returns the html to display an auto complete for resources. Only resources
  # belonging to customer id are returned. Unassigned resources (belonging to
  # no customer are also returned though).
  ###
  def auto_complete_for_resources(customer_id)
    text_field(:resource, :name, {:id => "resource_name_auto_complete", :size => 12, 'data-customer-id'=>customer_id })
  end

  ###
  # Returns the html for the field to select status for a task.
  ###
  def status_field(task)
    options = task.statuses_for_select_list
    can_close = {}
    if task.project and !current_user.can?(task.project, 'close')
      can_close[:disabled] = "disabled"
    end
    return select('task', 'status', options, {:selected => @task.status}, can_close)
  end

  ###
  # Returns a link that add the current user to the current tasks user list
  # when clicked.
  ###
  def add_me_link
    link_to("add me", "#", {
      "data-notification"=> render_to_string(:partial=> "tasks/notification",
                                             :locals => { :notification => current_user }),
      :id => "add_me"})
  end

  # Returns an array that show the start of ranges to be used
  # for a tag cloud
  def cloud_ranges(counts)
    # there are going to be 5 ranges defined in css:
    class_count = 5

    max = counts.max || 0
    min = counts.min || 0
    divisor = ((max - min) / class_count) + 1

    res = []
    class_count.times do |i|
      res << (i * divisor)
    end

    return res
  end

  ###
  # Returns a list of options to use for the project select tag.
  ###
  def options_for_user_projects(task)
    projects = current_user.projects.includes(:customer).except(:order).order("customers.name, projects.name")

    unless task.new_record? or task.project.nil? or projects.include?(task.project)
      projects << task.project
      projects = projects.sort_by { |project| project.customer.name + project.name }
    end
    options = grouped_client_projects_options(projects)

    return grouped_options_for_select(options, task.project_id, "Please select").html_safe
  end

  ##
  # Returns a list of services for the service select tag
  ##
  def options_for_task_services(customers, task)
    services = []
    customers.each {|c| services.concat(c.services.all) }
    services = services.uniq

    # detect if service_id in the list
    if Service.exists?(task.service_id)
      detected = services.detect {|s| s.id == task.service_id}
      services << Service.find(task.service_id) unless detected
    end

    result = '<option value="0" title="none">none</option>'
    services.each do |s|
      if task.service_id == s.id
        result += "<option value=\"#{s.id}\" title=\"#{s.description}\" selected=\"selected\">#{s.name}</option>"
      else
        result += "<option value=\"#{s.id}\" title=\"#{s.description}\">#{s.name}</option>"
      end
    end

    result += "<option disabled>―――――――</option>"
    # isQuoted
    if task.isQuoted
      result += "<option value=\"-1\" selected=\"selected\">Quoted</option>"
    else
      result += "<option value=\"-1\" title=\"This task is quoted\">Quoted</option>"
    end

    return result.html_safe
  end

  # Returns html to display the due date selector for task
  def due_date_field(task, permissions)
    task_due_at = task.due_at.nil? ? "" : task.due_at.utc.strftime("#{current_user.date_format}")
    milestone_due_at = task.milestone.try(:due_at)
    placeholder = milestone_due_at.nil? ? "" : milestone_due_at.strftime("#{current_user.date_format}")
    date_tooltip = (task.due_at.nil? and !milestone_due_at.nil?) ? "Target date from milestone" : "Set task due date"

    options = {
      :id => "due_at",
      :title => date_tooltip.html_safe,
      :rel => :tooltip,
      "data-placement" => :right,
      :placeholder => placeholder,
      :size => 12,
      :value => task_due_at,
      :autocomplete => "off"
    }
    options = options.merge(permissions['edit'])

    return text_field("task", "due_at", options)
  end

  def target_date(task)
    return _("Not set") if task.target_date.nil?
    # Before, the input date string is parsed into DateTime in UTC.
    # Now, the date part is converted from DateTime to string display in UTC, so that it doesn't change.
    return task.target_date.utc.strftime("#{current_user.date_format}")
  end

  def target_date_tooltip(task)
    return _("Manually overridden")                     if  task.due_at
    return _("From milestone %s", task.milestone.name)  if task.milestone.try(:due_at)
  end

  # Returns a hash of permissions for the current task and user
  def perms
    if @perms.nil?
      @perms = {}
      permissions = ['comment', 'edit', 'reassign', 'close', 'milestone']
      permissions.each do |p|
        if @task.project_id.to_i == 0 || current_user.can?(@task.project, p)
          @perms[p] = {}
        else
          @perms[p] = { :disabled => 'disabled' }
        end
      end

    end

    @perms
  end

  # Renders the last task the current user looked at
  def render_last_task
    if @task
      return render_to_string(:partial => "tasks/edit_form", :locals => {:ajax => true}, :layout => false)
    end
  end

  # Returns the html for a completely self contained unread toggle
  # for the given task and user
  def unread_toggle_for_task_and_user(task, user)
    classname = "task"
    classname += " unread" if task.unread?(user)

    content_tag(:span, :class => classname, :id => "task_#{ task.task_num }") do
      content_tag(:span, :class => "unread_icon") do
      end
    end
  end

  def options_for_changegroup
    cols = [["Grouped by Client", "client"], ["Grouped by Milestone", "milestone"], ["Grouped by Resolution", "resolution"], ["Grouped by Assigned", "assigned"]]
    current_user.company.properties.each do |p|
      cols << ["Grouped by #{p.name.camelize}", p.name.downcase]
    end
    cols << ["Not Grouped", "clear"]
    return options_for_select(cols, current_user.preference('task_grouping'))
  end

  def last_comment_date(task)
    date = if task.work_logs.size > 0 then task.work_logs.last.started_at else nil end
    if date
      distance_of_time_in_words(Time.now.utc, date)
    else
      ""
    end
  end

  def task_detail(task, user=current_user)
    options = {}
    options["Project"] = task.project.name
    options["Milestone"] = task.milestone.try(:name) || "None"
    options["Estimate"] = task.duration.to_i > 0 ? TimeParser.format_duration(task.duration) : "<span class='muted'>#{TimeParser.format_duration(task.default_duration)}(default)</span>"
    options["Deadline"] = task.due_at.nil? ? "Not specified" : due_in_words(task)
    options["Remaining"] = TimeParser.format_duration(task.minutes_left)
    options["Remaining"] += "(<span class='due_overdue'>exceeded by " + TimeParser.format_duration(task.worked_minutes - task.adjusted_duration) + "</span>)" if task.overworked?

    html = ''
    options.each do |k, v|
      html += "<b>#{k}</b>: #{v}<br/>"
    end

    html
  end

  def human_future_date(date, user)
    return %q[<span class="label label-important">unknown</span>].html_safe if date.nil?

    if date < user.tz.now.end_of_day
      %q[<span class="label label-warning">today</span>].html_safe
    elsif date < user.tz.now.end_of_day + 1.days
      %q[<span class="label label-info">tomorrow</span>].html_safe
    elsif date < user.tz.now.end_of_day + 7.days
      (%q[<span class="label">%s</span>] % user.tz.utc_to_local(date).strftime_localized("%a")).html_safe
    elsif date < user.tz.now.end_of_day + 30.days
      (%q[<span class="label">%s days</span>] % ((date - Time.now).round/86400)).html_safe
    elsif date < user.tz.now.end_of_day + 12.months
      (%q[<span class="label">%s</span>] % user.tz.utc_to_local(date).strftime_localized("%b")).html_safe
    else
      (%q[<span class="label">%s</span>] % date.strftime("%Y")).html_safe
    end
  end

  def work_log_attribute
    custom_attributes = current_user.company.custom_attributes.where(:attributable_type => "WorkLog")

    custom_attributes.each do |ca|
      return ca if ca.preset?
    end
    nil
  end

  def default_work_log_choice(attr)
    return nil if attr.nil?

    default_choice = attr.custom_attribute_choices.first
    # set latest used value as default
    last = @task.work_logs.worktimes.where(:user_id => current_user.id).last
    if last
      last_value = last.custom_attribute_values(:include => :choice).where(:custom_attribute_id => attr.id).first
      default_choice = last_value.choice if last_value
    end

    return default_choice
  end

  private

  def milestones_to_select_tag(milestones)

    options = ([[_("[None]"), "0"]] + milestones.collect {|c| [ h(c.name), c.id, c.due_at ] }).map do |array|
      date = array[2].nil? ? _('Not set') : array[2].utc.strftime("#{current_user.date_format}")
      selected = if (@task.milestone_id == array[1]) || (@task.milestone_id.nil? && array[1] == "0") then "selected=\"selected\"" else "" end
      text = if @task.milestone_id == array[1] and @task.milestone.complete? then "[#{array[0]}]" else array[0] end
      "<option value=\"#{array[1]}\" data-date=\"#{date}\" #{selected}>#{text}</option>"
    end

    return select_tag("task[milestone_id]", options.join(' ').html_safe, (perms[:milestone]||{ }).merge(:id=>'task_milestone_id'))  
  end
  
end
