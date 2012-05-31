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
    date_tooltip = _("Enter task due date.")

    options = {
      :id => "due_at", :title => date_tooltip.html_safe,
      :size => 12,
      :value => (task.due_at.nil? ? "" : task.due_at.utc.strftime("#{current_user.date_format}")),
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
  # Returns the notify emails for the given task, one per line
  def notify_emails_on_newlines(task)
    emails = task.notify_emails_array
    return emails.join("\n")
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

  # Get the next tasks for the nextTasks panel
  def nextTasks(count)
    return current_user.tasks.open_only.not_snoozed.order("tasks.weight DESC").limit(count)
  end

  def last_comment_date(task)
    date = if task.work_logs.size > 0 then task.work_logs.last.started_at else nil end
    if date
      distance_of_time_in_words(Time.now.utc, date).to_json.html_safe
    else
      ""
    end
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
