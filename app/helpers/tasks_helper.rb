# encoding: UTF-8
module TasksHelper
  def render_task_form(show_timer = true)
    render partial: 'tasks/form', locals: {show_timer: show_timer}
  end

  def render_task_dependants(t, depth, root_present)
    res = ''
    @printed_ids ||= []

    return if @printed_ids.include? t.id

    shown = task_shown?(t)

    @deps = []

    if session[:hide_dependencies].to_i == 1
      res << render(:partial => 'task_row', :locals => {:task => t, :depth => depth})
    else
      if root_present
        res << render(:partial => 'task_row', :locals => {:task => t, :depth => depth, :override_filter => !shown}) if (((!t.done?) && t.dependants.size > 0) || shown)

        @printed_ids << t.id

        if t.dependants.size > 0
          t.dependants.each do |child|
            next if @printed_ids.include? child.id
            res << render_task_dependants(child, (((!t.done?) && t.dependants.size > 0) || shown) ? (depth == 0 ? depth + 2 : depth + 1) : depth, true)
          end
        end
      else
        root = nil
        parents = []
        p = t
        while !p.nil? && p.dependencies.size > 0
          root = nil
          p.dependencies.each do |dep|
            root = dep if ((!dep.done?) && (!@deps.include?(dep.id)))
          end
          root ||= p.dependencies.first if (p.dependencies.first.id != p.id && !@deps.include?(p.dependencies.first.id))
          p = root
          @deps << root.id
        end
        res << render_task_dependants(root, depth, true) unless root.nil?
      end
    end
    res
  end

  # Returns the html to display a select field to set the tasks
  # milestone. The current milestone (if set) will be selected.
  def milestone_select(perms)
    milestones = Milestone.can_add_task.
        order('case when due_at IS NULL then 1 else 0 end, due_at, name').
        where('company_id = ? AND project_id = ?',
              current_user.company.id, selected_project).
        to_a

    if @task.has_milestone? and !milestones.include?(@task.milestone)
      milestones << @task.milestone
    end

    milestones_to_select_tag(milestones)
  end

  # Returns the html to display an auto complete for resources. Only resources
  # belonging to customer id are returned. Unassigned resources (belonging to
  # no customer are also returned though).
  def auto_complete_for_resources(customer_id)
    text_field(:resource, :name, {:id => 'resource_name_auto_complete', :size => 12, 'data-customer-id' => customer_id})
  end

  # Returns the html for the field to select status for a task.
  def status_field(task)
    options = task.statuses_for_select_list
    can_close = {}
    if task.project and !current_user.can?(task.project, 'close')
      can_close[:disabled] = 'disabled'
    end
    return select('task', 'status', options, {:selected => @task.status}, can_close)
  end

  # Returns a link that add the current user to the current tasks user list
  # when clicked.
  def add_me_link
    link_to(t('tasks.actions.add_me'), '#', {id: 'add_me'})
  end

  # Returns an array that show the start of ranges to be used
  # for a tag cloud
  def cloud_ranges(range, class_count = 5)
    max = range.max || 0
    min = range.min || 0
    divisor = ((max - min) / class_count) + 1

    class_count.times.map { |i| i * divisor }
  end

  # Returns a list of options to use for the project select tag.
  def options_for_user_projects(task, current_user = nil)
    projects = current_user.projects.includes(:customer).except(:order).order('customers.name, projects.name').joins(:project_permissions).where('project_permissions.can_create= ? or project_permissions.can_edit=?', true, true)
    unless task.new_record? or task.project.nil? or projects.include?(task.project)
      projects << task.project
      projects = projects.sort_by { |project| project.customer.name + project.name }
    end
    options = grouped_client_projects_options(projects)

    return grouped_options_for_select(options, task.project_id, :prompt => t('forms.select.please_select')).html_safe
  end

  ##
  # Returns a list of services for the service select tag
  ##

  def options_for_task_services(customers, task)
    services = []
    customers.each { |c| services.concat(c.services.all) }
    services = services.uniq

    # detect if service_id in the list
    if Service.exists?(task.service_id)
      detected = services.detect { |s| s.id == task.service_id }
      services << Service.find(task.service_id) unless detected
    end

    result = %Q[<option value="0" title="#{t('forms.select.none')}">#{t('forms.select.none')}</option>]
    services.each do |s|
      if task.service_id == s.id
        result += "<option value=\"#{s.id}\" title=\"#{s.description}\" selected=\"selected\">#{s.name}</option>"
      else
        result += "<option value=\"#{s.id}\" title=\"#{s.description}\">#{s.name}</option>"
      end
    end

    result += '<option disabled>―――――――</option>'
    # isQuoted
    if task.isQuoted
      result += %Q[<option value="-1" selected="selected">#{ t('tasks.services.quoted') }</option>]
    else
      result += %Q[<option value="-1" title="#{ t('tasks.services.quoted_title') }">#{ t('tasks.services.quoted') }</option>]
    end

    return result.html_safe
  end

  # Returns html to display the due date selector for task
  def due_date_field(task, permissions)
    task_due_at = task.due_at.nil? ? '' : task.due_at.utc.strftime(current_user.date_format)
    milestone_due_at = task.milestone.try(:due_at)
    placeholder = milestone_due_at.nil? ? '' : milestone_due_at.strftime(current_user.date_format)
    date_tooltip = if task.due_at.nil? && !milestone_due_at.nil?
                     t('hint.task.target_date_from_milestone')
                   else
                     t('hint.task.target_date_from_start')
                   end

    due_at = task.due_at || task.milestone.try(:due_at)
    html_class = ''
    if due_at and task.estimate_date and due_at.beginning_of_day < task.estimate_date.beginning_of_day
      html_class = 'error'
    end

    options = {
        :id => 'due_at',
        :title => date_tooltip.html_safe,
        :rel => :tooltip,
        'data-placement' => :right,
        :placeholder => placeholder,
        :size => 12,
        :value => task_due_at,
        :autocomplete => 'off',
        :class => html_class
    }
    options = options.merge(permissions['edit'])

    return text_field('task', 'due_at', options)
  end

  def target_date(task)
    return t('tasks.target_dates.not_set') if task.target_date.nil?
    # Before, the input date string is parsed into DateTime in UTC.
    # Now, the date part is converted from DateTime to string display in UTC, so that it doesn't change.
    return task.target_date.utc.strftime(current_user.date_format)
  end

  def target_date_tooltip(task)
    return t('tasks.target_dates.manually_overridden') if task.due_at
    return t('tasks.target_dates.from_milestone', milestone: task.milestone.name) if task.milestone.try(:due_at)
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
          @perms[p] = {:disabled => 'disabled'}
        end
      end

    end

    @perms
  end

  # Returns the html for a completely self contained unread toggle
  # for the given task and user
  def unread_toggle_for_task_and_user(task, user)
    classname = 'task'
    classname += if task.unread?(user)
                   ' unread'
                 else
                   ' read'
                 end

    content_tag(:span, :class => classname, :id => "task_#{ task.task_num }") do
      content_tag(:span, :class => 'unread_icon') do
      end
    end
  end

  def options_for_changegroup
    return options_for_select(cols_options, current_user.preference('task_grouping'))
  end

  def last_comment_date(task)
    if task.work_logs.size > 0
      task.work_logs.last.started_at
    else
      task.updated_at
    end
  end

  def task_detail(task, user = current_user)
    task.due_at ||= task.milestone.due_at if task.milestone
    options = {
        task.human_name(:status) => task.human_value(:open_or_closed),
        task.human_name(:project) => task.project.name,
        task.human_name(:milestone) => task.milestone.try(:name) || t('shared.none'),
        task.human_name(:estimate) => task.duration.to_i > 0 ? TimeParser.format_duration(task.duration) : "<span class='muted'>#{TimeParser.format_duration(task.default_duration)}(default)</span>",
        task.human_name(:target) => task.due_at.nil? ? t('shared.not_specified') : due_in_words(task),
        task.human_name(:remaining) => TimeParser.format_duration(task.minutes_left)
    }
    if task.overworked?
      options[task.human_name(:remaining)] +=
          "(<span class='due_overdue'>exceeded by " +
              TimeParser.format_duration(task.worked_minutes - task.adjusted_duration) +
              '</span>)'
    end

    options.inject('') { |html, kv| html + ('<b>%s</b>: %s<br/>' % kv) }
  end

  def human_future_date(date, tz)
    return t('shared.unknown') unless date

    tz_day_end = tz.now.end_of_day
    local_date = tz.utc_to_local(date.utc)

    text =
        case
          when date < tz_day_end - 12.months
            '<span class="label">%s</span>' % local_date.year
          when date < tz_day_end - 30.days
            '<span class="label">%s</span>' % l(local_date, format: '%b')
          when date < tz_day_end - 7.days
            '<span class="label">%s</span>' % t('shared.x_days_ago', :x => (Time.now - date).round / 86400)
          when date < tz_day_end - 2.days
            '<span class="label">last %s</span>' % l(local_date, format: '%a')
          when date < tz_day_end - 1.day
            '<span class="label label-info">%s</span>' % t('shared.yesterday')
          when date < tz_day_end
            '<span class="label label-warning">%s</span>' % t('shared.today')
          when date < tz_day_end + 1.days
            '<span class="label label-info">%s</span>' % t('shared.tomorrow')
          when date < tz_day_end + 7.days
            '<span class="label">%s</span>' % l(local_date, format: '%a')
          when date < tz_day_end + 30.days
            '<span class="label">%s days</span>' % ((date - Time.now).round/86400)
          when date < tz_day_end + 12.months
            '<span class="label">%s</span>' % l(local_date, format: '%b')
          else
            '<span class="label">%s</span>' % local_date.year
        end

    content_tag('time', text.html_safe, :datetime => date.iso8601, :title => date.to_date)
  end

  def work_log_attribute
    custom_attributes = current_user.company.custom_attributes.where(:attributable_type => 'WorkLog')

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

  def worked_and_duration_class(task)
    task.worked_minutes > task.duration ? 'overtime' : ''
  end

  def groupByOptions
    options = "<ul class='dropdown-menu'>"
    cols_options.each do |key, val|
      val = 'Not gropued' if val == 'clear'
      options<<"<li class='groupByOption'>#{val.capitalize}</li>"
    end
    options<<'</ul>'
    return options
  end

  private

  def milestones_to_select_tag(milestones)
    options = [%Q[<option value="0" title="#{t('forms.select.please_select')}">#{t('forms.select.none')}</option>]] + milestones.collect do |milestone|
      date = milestone.due_at.nil? ? t('shared.not_set') : l(milestone.due_at, format: current_user.date_format)

      selected = if (@task.milestone_id == milestone.id) || (@task.milestone_id.nil? && milestone.id == '0')
                   'selected="selected"'
                 else
                   ''
                 end
      text = if @task.milestone_id == milestone.id && @task.milestone.closed?
               "[#{milestone.name}]"
             else
               milestone.name
             end

      "<option value=\"#{milestone.id}\" data-date=\"#{date}\" #{selected} title=\"#{milestone_status_tip(milestone.status_name)}\">#{text}</option>"
    end

    title = if @task.milestone
              milestone_status_tip(@task.milestone.status_name)
            else
              ''
            end
    html_options = {
        :rel => 'tooltip',
        :title => title,
        :id => :task_milestone_id,
        'data-placement' => :right
    }

    return select_tag('task[milestone_id]', options.join(' ').html_safe, (perms[:milestone]||{}).merge(html_options))
  end

  def cols_options
    cols = [[t('tasks.groupings.by_client'), 'client'],
            [t('tasks.groupings.group_by', thing: Milestone.model_name.human), 'milestone'],
            [t('tasks.groupings.by_resolution'), 'resolution'],
            [t('tasks.groupings.by_assigned'), 'assigned']]
    current_user.company.properties.each do |p|
      cols << [t('tasks.groupings.group_by', thing: p.name.camelize), p.name.downcase]
    end
    cols << [t('tasks.groupings.not_grouped'), 'clear']
  end

end
