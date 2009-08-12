module TasksHelper

  def print_title
    filters = []
    title = "<div style=\"float:left\">"
    status_ids = TaskFilter.filter_status_ids(session)
    if status_ids.any?
      statuses = status_ids.map { |id| Task.status_types[id] }
      title << " #{ _('%s tasks', statuses.join(", ")) } ["
    else
      title << "#{_'Tasks'} ["
    end

    TaskFilter.filter_ids(session, :filter_customer).each do |id|
      filters << Customer.find(id).name unless id == TaskFilter::ALL_CUSTOMERS
    end

    
    TaskFilter.filter_ids(session, :filter_project).each do |id|
      filters << Project.find(id).name unless id == TaskFilter::ALL_PROJECTS
    end

    TaskFilter.filter_user_ids(session, false).each do |id|
      filters << User.find(id).name if id != TaskFilter::ALL_USERS and id > 0
    end

    filters << current_user.company.name if filters.empty?

    title << filters.join(' / ')

    title << "]</div><div style=\"float:right\">#{tz.now.strftime_localized("#{current_user.time_format} #{current_user.date_format}")}</div><div style=\"clear:both\"></div>"

    "<h3>#{title}</h3>"

  end

  ###
  # Returns true if the given tasks should be shown in the list.
  # The only time it won't return true is if the task is closed and the
  # filter isn't set to show the closed tasks.
  ###
  def task_shown?(task)
    status_ids = TaskFilter.filter_status_ids(session)
    return (status_ids.empty? or status_ids.include?(task.status))
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
    if @task.id
      milestones = Milestone.find(:all, :order => 'due_at, name', :conditions => ['company_id = ? AND project_id = ? AND completed_at IS NULL', current_user.company.id, selected_project])
      return select('task', 'milestone_id', [[_("[None]"), "0"]] + milestones.collect {|c| [ c.name, c.id ] }, {}, perms['milestone'])
    else
      milestone_id = TaskFilter.new(self, session).milestone_ids.first
      milestones = Milestone.find(:all, :order => 'due_at, name', :conditions => ['company_id = ? AND project_id = ? AND completed_at IS NULL', current_user.company.id, selected_project])
      return select('task', 'milestone_id', [[_("[None]"), "0"]] + milestones.collect {|c| [ c.name, c.id ] }, {:selected => milestone_id || 0 }, perms['milestone'])
    end
  end

  ###
  # Returns the html to display an auto complete for resources. Only resources
  # belonging to customer id are returned. Unassigned resources (belonging to
  # no customer are also returned though).
  ###
  def auto_complete_for_resources(customer_id)
    options = {
      :select => 'complete_value', 
      :tokens => ',',
      :url => { :action => "auto_complete_for_resource_name", 
        :customer_id => customer_id },
      :after_update_element => "addResourceToTask"
    }

    return text_field_with_auto_complete(:resource, :name, { :size => 12 }, options)
  end

  ###
  # Returns the html to display an auto complete for task dependencies. When
  # a choice is made, the dependency will be added to the page (but not saved
  # to the db until the task is saved)
  ###
  def auto_complete_for_dependencies
    auto_complete_field('dependencies_input', 
                        { :url => { :action => 'dependency_targets' }, 
                          :min_chars => 1, 
                          :frequency => 0.5, 
                          :indicator => 'loading', 
                          :after_update_element => "addDependencyToTask"
                        })
  end

  ###
  # Returns the html for the field to select status for a task.
  ###
  def status_field(task)
    options = []
    options << [_("Leave Open"), 0] if task.status == 0
    options << [_("Revert to Open"), 0] if task.status != 0
    options << [_("Set in Progress"), 1] if task.status == 0
    options << [_("Leave as in Progress"), 1] if task.status == 1
    options << [_("Close"), 2] if task.status == 0 || task.status == 1
    options << [_("Leave Closed"), 2] if task.status == 2
    options << [_("Set as Won't Fix"), 3] if task.status == 0 || task.status == 1
    options << [_("Leave as Won't Fix"), 3] if task.status == 3
    options << [_("Set as Invalid"), 4] if task.status == 0 || task.status == 1
    options << [_("Leave as Invalid"), 4] if task.status == 4
    options << [_("Set as Duplicate"), 5] if task.status == 0 || task.status == 1
    options << [_("Leave as Duplicate"), 5] if task.status == 5
    options << [_("Wait Until"), 6] if task.status < 2
    
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
    res += '<div id="defer_options" style="display:none;">'
    res += select('task', 'hide_until', defer_options, { :selected => "" })
    res += "</div>"

    return res
  end

  ###
  # Returns an icon to set whether user is assigned to task.
  # The icon will have a link to toggle this attribute if the user
  # is allowed to assign for the task project.
  ###
  def assigned_icon(task, user)
    classname = "icon tooltip assigned"
    classname += " is_assigned" if task.users.include?(user)
    content = content_tag(:span, "*", :class => classname, 
                          :title => _("Click to toggle whether this task is assigned to this user"))

    if task.project.nil? or current_user.can?(task.project, "reassign")
      content = link_to_function(content, "toggleTaskIcon(this, 'assigned', 'is_assigned')")
    end

    return content
  end

  ###
  # Returns an icon to set whether a user should receive notifications
  # for task.
  # The icon will have a link to toggle this attribute.
  ###
  def notify_icon(task, user)
    classname = "icon tooltip notify"

    if task.should_be_notified?(user)
      classname += " should_notify" 
    end

    content = content_tag(:span, "*", :class => classname, 
                          :title => _("Click to toggle whether this user will receive a notification when task is saved"))
    content = link_to_function(content, "toggleTaskIcon(this, 'notify', 'should_notify'); highlightActiveNotifications()")

    return content
  end

  ###
  # Returns a link that add the current user to the current tasks user list
  # when clicked.
  ###
  def add_me_link
    link_to_function(_("add me")) do |page|
      page.insert_html(:bottom, "task_notify", 
                       :partial => "notification", 
                       :locals => { :notification => current_user })
    end
  end

  ###
  # Returns a field that will allow users or email address to be added
  # to the task notify list.
  ###
  def add_notifier_field
    html_options = {
      :size => "12", 
      :title => _("Add users by name or email"), 
      :class => "tooltip"
    }
    text_field_with_auto_complete(:user, :name, html_options,
                                  :after_update_element => "addUserToTask")
  end

  ###
  # Returns links to filter the current task list by tags
  ###
  def tag_links(tags_to_counts_hash)
    links = []
    
    tags_to_counts_hash.each do |tag, count|
      name = tag.name
      links << link_to("#{ name } (#{ count })", params.merge(:tag => name))
    end
    
    links = links.sort.join(", ")
    return links
  end

  ###
  # Returns a list of options to use for the project select tag.
  ###
  def options_for_user_projects(task)
    projects = current_user.projects.find(:all, :include => "customer", :order => "customers.name, projects.name")

    last_customer = nil
    options = []

    projects.each do |project|
      if project.customer != last_customer
        options << [ h(project.customer.name), [] ]
        last_customer = project.customer
      end

      options.last[1] << [ project.name, project.id ]
    end

    return grouped_options_for_select(options, task.project_id)
  end

  ###
  # Returns an array to use as the options for a select
  # to change a work log's status.
  ###
  def work_log_status_options
    options = []
    options << [_("Leave Open"), 0] if @task.status == 0
    options << [_("Revert to Open"), 0] if @task.status != 0
    options << [_("Set in Progress"), 1] if @task.status == 0
    options << [_("Leave as in Progress"), 1] if @task.status == 1
    options << [_("Close"), 2] if @task.status == 0 || @task.status == 1
    options << [_("Leave Closed"), 2] if @task.status == 2
    options << [_("Set as Won't Fix"), 3] if @task.status == 0 || @task.status == 1
    options << [_("Leave as Won't Fix"), 3] if @task.status == 3
    options << [_("Set as Invalid"), 4] if @task.status == 0 || @task.status == 1
    options << [_("Leave as Invalid"), 4] if @task.status == 4
    options << [_("Set as Duplicate"), 5] if @task.status == 0 || @task.status == 1
    options << [_("Leave as Duplicate"), 5] if @task.status == 5

    return options
  end

  ###
  # Returns a hash to use as the options for the task
  # status dropdown on the work log edit page.
  ###
  def work_log_status_html_options
    options = {}
    options[:disabled] = "disabled" unless current_user.can?( @task.project, "close" )

    return options
  end

  # Returns a list of customers/clients that could a log
  # could potentially be attached to
  def work_log_customer_options(log)
    res = @log.task.customers.clone
    res << @log.task.project.customer

    res = res.uniq.compact
    return objects_to_names_and_ids(res)
  end

  # Returns html to display the due date selector for task
  def due_date_field(task, permissions)
    date_tooltip = _("Enter task due date.<br/>For recurring tasks, try:<br/>every day<br/>every thursday<br/>every last friday<br/>every 14 days<br/>every 3rd monday <em>(of a month)</em>")

    options = { 
      :id => "due_at", :class => "tooltip", :title => date_tooltip,
      :size => 12,
      :value => formatted_date_for_current_user(task.due_date)
    }
    options = options.merge(permissions["prioritize"])

    if !task.repeat.blank?
      options[:value] = @task.repeat_summary
    end

    return text_field("task", "due_at", options)
  end

  # Returns the notify emails for the given task, one per line
  def notify_emails_on_newlines(task)
    emails = (task.notify_emails || "").strip.split(",")
    return emails.join("\n")
  end

  # Returns basic task info as a tooltip
  def task_info_tip(task)
    values = []
    values << [ _("Description"), task.description ]
    comment = task.last_comment
    if comment
      values << [ _("Last Comment"), "#{ comment.user.shout_nick }:<br/>#{ comment.body.gsub(/\n/, '<br/>') }" ]
    end
    
    return task_tooltip(values)
  end

  # Returns information about the customer as a tooltip
  def task_customer_tip(customer)
    values = []
    values << [ _("Contact Name"), customer.contact_name ]
    values << [ _("Contact Email"), customer.contact_email ]
    customer.custom_attribute_values.each do |cav|
      values << [ cav.custom_attribute.display_name, cav.to_s ]
    end
    
    return task_tooltip(values)
  end

  # Returns a tooltip showing milestone information for a task
  def task_milestone_tip(task)
    return if task.milestone_id.to_i <= 0

    return task_tooltip([ _("Due Date"), formatted_date_for_current_user(task.milestone.due_date) ])
  end

  # Returns a tooltip showing the users linked to a task
  def task_users_tip(task)
    values = []
    task.users.each do |user|
      icons = image_tag("user.png")
      values << [ user.name, icons ]
    end

    task.watchers.each do |user|
      values << [ user.name ]
    end

    return task_tooltip(values)
  end

  # Converts the given array into a table that looks good in a toolip
  def task_tooltip(names_and_values)
    res = "<table id=\"task_tooltip\" cellpadding=0 cellspacing=0>"
    names_and_values.each do |name, value|
      res += "<tr><th>#{ name }</th>"
      res += "<td>#{ value }</td></tr>"
    end
    res += "</table>"
    return escape_once(res)
  end

end
