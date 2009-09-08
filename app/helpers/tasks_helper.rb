module TasksHelper

  def print_title
    filters = []
    title = "<div style=\"float:left\">"

    title << filters.join(' / ')

    title << "]</div><div style=\"float:right\">#{tz.now.strftime_localized("#{current_user.time_format} #{current_user.date_format}")}</div><div style=\"clear:both\"></div>"

    "<h3>#{title}</h3>"

  end

  ###
  # Returns true if the given tasks should be shown in the list.
  # The only time it won't return true is if the task is closed and the
  # filter isn't set to show the closed tasks.
  # N.B This is unused and can be removed once list_old is
  ###
  def task_shown?(task)
    true
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

  # Returns the js to watch a task's project selector
  def task_project_watchers_js
    js = <<-EOS
    new Form.Element.EventObserver('task_project_id', function(element, value) {new Ajax.Updater('task_milestone_id', '/tasks/get_milestones', {asynchronous:true, evalScripts:true, onComplete:function(request){hideProgress();}, onLoading:function(request){showProgress();}, parameters:'project_id=' + value, insertion: updateSelect })});
    new Form.Element.EventObserver('task_project_id', function(element, value) {new Ajax.Updater('task_users', '/tasks/get_owners', {asynchronous:true, evalScripts:true, onComplete:function(request){reset_owners();}, parameters:'project_id=' + value, insertion: updateSelect, onLoading:function(request){ remember_user(); } })});
    EOS
    
    return javascript_tag(js)
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

    return task_tooltip([ [ _("Milestone Due Date"), formatted_date_for_current_user(task.milestone.due_date) ] ])
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

  # Returns a hash of permissions for the current task and user
  def perms
    if @perms.nil?
      @perms = {}
      permissions = ['comment', 'edit', 'reassign', 'prioritize', 'close', 'milestone']
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
    @task = current_user.company.tasks.find_by_id(session[:last_task_id], 
                                                  :conditions => [ "project_id IN (#{ current_project_ids })" ])
    if @task
      return render_to_string(:action => "edit", :layout => false)
    end
  end

  # Returns the open tr tag for the given task in a task list
  def task_row_tr_tag(task)
    class_name = cycle("odd", "even") 
    class_name += " task"
    class_name += " selected" if task.id == session[:last_task_id] 
    class_name += " unread" if task.unread?(current_user)
    class_name += " unassigned" if task.users.count == 0

    return tag(:tr, {
                 :id => "task_row_#{ task.task_num }", 
                 :class => class_name, 
                 :onclick => "showTaskInPage(#{ task.task_num}); return false;"
               }, true)
  end

  # Returns the html for a completely self contained unread toggle
  # for the given task and user
  def unread_toggle_for_task_and_user(task, user)
    classname = "task"
    classname += " unread" if task.unread?(user)

    content_tag(:span, :class => classname, :id => "task_#{ task.task_num }") do
      content_tag(:span, :class => "unread_icon") do
        link_to_function("<span>*</span>", "toggleTaskUnread(event, #{ user.id })")
      end
    end
  end

  # Returns a sort hint for sorting the given task. 
  # Uses unread status and whether a user is a task owner or watcher
  def default_sort_hint_for_task(task)
    if task.unread?(current_user)
      return 10
    elsif task.linked_users.empty?
      return 9
    elsif task.linked_users.include?(current_user)
      return 8
    else
      return 1
    end
  end

  # Returns a link that allows the user to toggle whether the
  # full task history or only comments are shown
  def toggle_history_view_link
    only_comments = (session[:only_comments].to_i == 0)
    str = only_comments ? _("Showing Full History") : _("Showing Only Comments")

    return link_to_remote(str, :loading => "showProgress();", :complete => "hideProgress();",
                          :url => { :action => 'toggle_history', :id => @task.id })
  end

end
