module TasksHelper

  def pri_color(severity, priority)
    color = "#b0d295"
    color = "#f2ab99" if (priority + severity)/2.0 > 0.5
    color = "#FF6666" if (priority + severity)/2.0 > 1.5
    color = "#e7e0c4" if (priority + severity)/2 < -0.5
    color = "#F3F3F3" if (priority + severity)/2 < -1.5

    " style = \"background-color: #{color};\""

  end

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

  def task_shown?(t)
    return true
    # N.B. Is this still necessary? It seems like the deciding which 
    # tasks is already done in the controller. BW

    # shown = true
    # if session[:filter_status].to_i >= 0
    #   if session[:filter_status].to_i == 0
    #     shown = ( t.status == 0 || t.status == 1 ) if shown
    #   elsif session[:filter_status].to_i == 2
    #     shown = t.status > 1 if shown
    #   else
    #     shown = session[:filter_status].to_i == t.status if shown
    #   end
    # end

    milestones = TaskFilter.filter_ids(session, :filter_milestone, TaskFilter::ALL_MILESTONES)
    if shown and milestones.any?
      shown = milestones.include?(t.milestone_id)
    end

    customers = TaskFilter.filter_ids(session, :filter_customer, TaskFilter::ALL_CUSTOMERS)
    if shown and customers.any?
      shown = customers.include?(t.project.customer_id)
    end

    projects = TaskFilter.filter_ids(session, :filter_project, TaskFilter::ALL_PROJECTS)
    projects += milestones.map { |m| Milestone.find(m).project_id }
    if shown and projects.any?
      shown = projects.include?(t.project.id)
    end

    user_ids = TaskFilter.filter_user_ids(session, false)
    all_users = user_ids.delete(TaskFilter::ALL_USERS)
    if shown and !all_users and user_ids.any?
      task_user_ids = t.users.map { |u| u.id }
      shown = user_ids.detect { |id| task_user_ids.include?(id) }
    elsif shown and !all_users and TaskFilter.filter_user_ids(session, true).any?
      shown = t.users.empty?
    end


    shown
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
    if task.project and current_user.can?(task.project, 'close')
      can_close[:disabled] = "disabled"
    end
					
    defer_options = []
    defer_options << [_("Tomorrow"), tz.local_to_utc(tz.now.at_midnight + 1.days).to_s(:db)  ]
    defer_options << [_("End of week"), tz.local_to_utc(tz.now.beginning_of_week + 4.days).to_s(:db)  ]
    defer_options << [_("Next week"), tz.local_to_utc(tz.now.beginning_of_week + 7.days).to_s(:db) ]
    defer_options << [_("One week"), tz.local_to_utc(tz.now.at_midnight + 7.days).to_s(:db) ]
    defer_options << [_("Next month"), tz.local_to_utc(tz.now.next_month.beginning_of_month).to_s(:db)]
    defer_options << [_("One month"), tz.local_to_utc(tz.now.next_month.at_midnight).to_s(:db)]				
    
    res = select('task', 'status', options, {:selected => @task.status}, can_close)
    res += '<div id="defer_options" style="display:none;">'
    res += select('task', 'hide_until', defer_options)
    res += "</div>"

    return res
  end

  ###
  # Returns an icon to set whether user is assigned to task.
  # The icon will have a link to toggle this attribute if the user
  # is allowed to assign for the task project.
  ###
  def assigned_icon(task, user)
    classname = "icon"
    classname += " assigned" if task.users.include?(user)
    content = content_tag(:span, "", :class => classname)

    if current_user.can?(task.project, "reassign")
      content = link_to_function(content)
    end

    return content
  end

  ###
  # Returns an icon to set whether a user should receive notifications
  # for task.
  # The icon will have a link to toggle this attribute.
  ###
  def notify_icon(task, user)
    classname = "icon"
    classname += " notify"

    content = content_tag(:span, "", :class => classname)
    content = link_to_function(content)

    return content
  end
end
