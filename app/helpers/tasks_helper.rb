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
  # Returns the project id that should be selected based on the current 
  # session and filters.
  ### 
  def selected_project
    if @task.project_id > 0
      selected_project = @task.project_id
      last_project_id = TaskFilter.filter_ids(session, :last_project_id).first
      project_id = TaskFilter.filter_ids(session, :filter_project).first
    elsif last_project_id.to_i > 0 && Project.exists?(last_project_id)
      selected_project = last_project_id
    elsif project_id.to_i > 0 && Project.exists?(project_id)
      selected_project = project_id
    else
      selected_project = current_user.projects.find(:first, :order => 'name').id
    end
  
    begin
      selected_project = current_user.projects.find(selected_project).id 
    rescue 
      selected_project = current_user.projects.find(:first, :order => 'name').id
    end

    return selected_project
  end

  ###
  # Returns the html to display a select field to set the tasks 
  # milestone. The current milestone (if set) will be selected.
  ###
  def milestone_select(perms)
    if @task.id
      return select('task', 'milestone_id', [[_("[None]"), "0"]] + Milestone.find(:all, :order => 'name', :conditions => ['company_id = ? AND project_id = ? AND completed_at IS NULL', current_user.company.id, selected_project] ).collect {|c| [ c.name, c.id ] }, {}, perms['milestone'])
    else
      milestone_id = TaskFilter.new(self, session).milestone_ids.first
      return select('task', 'milestone_id', [[_("[None]"), "0"]] + Milestone.find(:all, :order => 'name', :conditions => ['company_id = ? AND project_id = ? AND completed_at IS NULL', current_user.company.id, selected_project] ).collect {|c| [ c.name, c.id ] }, {:selected => milestone_id || 0 }, perms['milestone'])
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
        :customer_id => customer_id }
    }

    return text_field_with_auto_complete(:resource, :name, { :size => 12 }, options)
  end

end
