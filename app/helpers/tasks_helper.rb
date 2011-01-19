# encoding: UTF-8
module TasksHelper

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

    milestones = Milestone.order('due_at, name').where('company_id = ? AND project_id = ? AND completed_at IS NULL', current_user.company.id, selected_project)
    if @task.id
      return select('task', 'milestone_id', [[_("[None]"), "0"]] + milestones.collect {|c| [ c.name, c.id ] }, {}, perms['milestone'])
    else
      return select('task', 'milestone_id', [[_("[None]"), "0"]] + milestones.collect {|c| [ c.name, c.id ] }, {:selected => 0}, perms['milestone'])
    end
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
    options << [_("Wait Until"), Task::MAX_STATUS+1]

    can_close = {}
    if task.project and !current_user.can?(task.project, 'close')
      can_close[:disabled] = "disabled"
    end

    defer_options = [ "" ]
    defer_options << [_("Tomorrow"), tz.local_to_utc(tz.now.at_midnight + 1.days).to_s(:db)  ]
    defer_options << [_("End of week"), tz.local_to_utc(tz.now.beginning_of_week + 4.days).to_s(:db)  ]
    defer_options << [_("Next week"), tz.local_to_utc(tz.now.beginning_of_week + 7.days).to_s(:db) ]
    defer_options << [_("One week"), tz.local_to_utc(tz.now.at_midnight + 7.days).to_s(:db) ]
    defer_options << [_("Next month"), tz.local_to_utc(tz.now.next_month.beginning_of_month).to_s(:db)]
    defer_options << [_("One month"), tz.local_to_utc(tz.now.next_month.at_midnight).to_s(:db)]

    res = select('task', 'status', options, {:selected => @task.status}, can_close)
    res += '<div id="defer_options" style="display:none;">'.html_safe
    res += select('task', 'hide_until', defer_options, { :selected => "" })
    res += "</div>".html_safe

    return res
  end

  ###
  # Returns a link that add the current user to the current tasks user list
  # when clicked.
  ###
  def add_me_link
    link_to_function(_("add me")) do |page|
      html = render_to_string(:partial => "tasks/notification", :locals => { :notification => current_user })
      page << "jQuery('#task_notify').append('#{escape_javascript html}')"
      page << "if(!jQuery('input[name=\"assigned[]\"]:enabled').size()) {jQuery('#task_notify>div.watcher:last>label>a').trigger('click');}"
    end
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

    unless  task.new_record? or projects.include?(task.project)
      projects<< task.project
      projects=projects.sort_by { |project| project.customer.name + project.name }
    end
    options = grouped_client_projects_options(projects)

    return grouped_options_for_select(options, task.project_id, "Please select").html_safe
  end

  # Returns html to display the due date selector for task
  def due_date_field(task, permissions)
    date_tooltip = _("Enter task due date.")

    options = {
      :id => "due_at", :class => "tooltip datefield", :title => date_tooltip.html_safe,
      :size => 12,
      :value => formatted_date_for_current_user(task.due_date),
      :autocomplete => "off"
    }
    options = options.merge(permissions['edit'])

    return text_field("task", "due_at", options)
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
      return render_to_string(:template => "tasks/edit", :layout => false)
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
    cols = [["Grouped by Client", "client"], ["Grouped by Milestone", "milestone"], ["Grouped by Resolution", "resolution"]]
    current_user.company.properties.each do |p|
      cols << ["Grouped by #{p.name.camelize}", p.name.downcase]
    end
    cols << ["Not Grouped", "clear"]
    return options_for_select(cols, current_user.preference('task_grouping'))
  end
end
