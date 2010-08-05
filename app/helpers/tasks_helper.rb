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
    if @task.id
      milestones = Milestone.find(:all, :order => 'due_at, name', :conditions => ['company_id = ? AND project_id = ? AND completed_at IS NULL', current_user.company.id, selected_project])
      return select('task', 'milestone_id', [[_("[None]"), "0"]] + milestones.collect {|c| [ c.name, c.id ] }, {}, perms['milestone'])
    else
      milestones = Milestone.find(:all, :order => 'due_at, name', :conditions => ['company_id = ? AND project_id = ? AND completed_at IS NULL', current_user.company.id, selected_project])
      return select('task', 'milestone_id', [[_("[None]"), "0"]] + milestones.collect {|c| [ c.name, c.id ] }, {:selected => 0 }, perms['milestone'])
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
      page.insert_html(:bottom, "task_notify",
                       :partial => "tasks/notification",
                       :locals => { :notification => current_user })
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
    projects = current_user.projects.find(:all, :include => "customer", :order => "customers.name, projects.name")

    unless  task.new_record? or projects.include?(task.project)
      projects<< task.project
      projects=projects.sort_by { |project| project.customer.name + project.name }
    end
    last_customer = nil
    options = []

    projects.each do |project|
      if project.customer != last_customer
        options << [ h(project.customer.name), [] ]
        last_customer = project.customer
      end

      options.last[1] << [ project.name, project.id ]
    end

    return grouped_options_for_select(options, task.project_id, "Please select").html_safe
  end


  ###
  # Returns an array to use as the options for a select
  # to change a work log's status.
  ###
  def work_log_status_options
    options = []
#this code make assumtion about internal task structure
#TODO: move it to Task model
    options << [_("Leave Open"), Task::OPEN] if !@task.resolved?
    options << [_("Revert to Open"), Task::OPEN] if @task.resolved?
    options << [_("Close"), Task::CLOSED] if !@task.resolved?
    options << [_("Leave Closed"),Task::CLOSED] if @task.closed?
    options << [_("Set as Won't Fix"), Task::WILL_NOT_FIX] if !@task.resolved?
    options << [_("Leave as Won't Fix"),Task::WILL_NOT_FIX ] if @task.will_not_fix?
    options << [_("Set as Invalid"), Task::INVALID] if !@task.resolved?
    options << [_("Leave as Invalid"), Task::INVALID] if @task.invalid?
    options << [_("Set as Duplicate"), Task::DUPLICATE] if !@task.resolved?
    options << [_("Leave as Duplicate"), Task::DUPLICATE] if @task.duplicate?

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
      :id => "due_at", :class => "tooltip", :title => date_tooltip.html_safe,
      :size => 12,
      :value => formatted_date_for_current_user(task.due_date)
    }
    options = options.merge(permissions['edit'])

    if !task.repeat.blank?
      options[:value] = @task.repeat_summary
    end

    js = <<-EOS
    jQuery(function() {
      jQuery("#due_at").datepicker({ constrainInput: false,
                                      dateFormat: '#{ current_user.dateFormat }'
                                   });
    });
    EOS

    return text_field("task", "due_at", options) + javascript_tag(js)
  end

  # Returns the notify emails for the given task, one per line
  def notify_emails_on_newlines(task)
    emails = task.notify_emails_array
    return emails.join("\n")
  end

  # Returns basic task info as a tooltip
  def task_info_tip(task)
    values = []
    values << [ _("Description"), task.description ]
    comment = task.last_comment
    if comment
      values << [ _("Last Comment"), "#{ comment.user.name }:<br/>#{ comment.body.gsub(/\n/, '<br/>') }".html_safe ]
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

    return task_tooltip([ [ _("Milestone Due Date"), formatted_date_for_current_user(task.milestone.due_date) ] ])
  end

  # Converts the given array into a table that looks good in a toolip
  def task_tooltip(names_and_values)
    res = "<table id=\"task_tooltip\" cellpadding=0 cellspacing=0>"
    names_and_values.each do |name, value|
      res += "<tr><th>#{ name }</th>"
      res += "<td>#{ value }</td></tr>"
    end
    res += "</table>"
    return res.html_safe
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
    @task = Task.accessed_by(current_user).find_by_id(session[:last_task_id])
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
        link_to_function("<span>*</span>".html_safe, "toggleTaskUnread(event, #{ user.id })")
      end
    end
  end
end
