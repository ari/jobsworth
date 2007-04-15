# The methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def tz
    Timezone.get(@session[:user].time_zone)
  end

  def online_users
    User.count( ["last_ping_at > '#{2.minutes.ago.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND company_id=#{session[:user].company_id}"] )
  end

  def user_online?(user_id)
    return User.count( ["id = #{user_id} AND last_ping_at > '#{2.minutes.ago.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND company_id=#{session[:user].company_id}"] ) > 0
  end

  def current_user
    @session[:user]
  end

  def user_name
    @user_name = current_user.name
  end

  def company_name
    current_user.company.name
  end

  def current_projects
    @current_projects ||= User.find(session[:user].id).projects.find(:all, :order => "projects.customer_id, projects.name",
                                                           :conditions => [ "projects.company_id = ? AND completed_at IS NULL", current_user.company_id ], :include => :customer )
  end

  def current_project_ids
    projects = current_projects
    if projects.empty?
      @current_project_ids ||= "0"
    else
      @current_project_ids ||= projects.collect{|p|p.id}.join(',')
    end
    @current_project_ids
  end

  # List of completed milestone ids, joined with ,
  def completed_milestone_ids
    @milestone_ids ||= Milestone.find(:all, :conditions => ["company_id = ? AND completed_at IS NOT NULL", session[:user].company_id]).collect{ |m| m.id }.join(',')
    @milestone_ids = "-1" if @milestone_ids == ''
    @milestone_ids
  end

  def current_pages
    @pages ||= Page.find(:all, :order => 'updated_at, name', :conditions => [ "company_id = ? AND project_id IN (#{current_project_ids})", current_user.company_id ] )
  end

  def urlize(name)
    name.to_s.gsub(/ /, "-").downcase
  end

  def worked_nice(minutes)
    res = ''
    weeks = days = hours = 0

    if minutes >= 60
      hours = minutes / 60
      minutes = minutes - (hours * 60)

      if hours >= 8
        days = hours / 8
        hours = hours - (days * 8)

        if days >= 5
          weeks = days / 5
          days = days - (weeks * 5)
          res += "#{weeks}#{_('w')}#{' ' if session[:user].duration_format == 0}"
        end

        res += "#{days}#{_('d')}#{' ' if session[:user].duration_format == 0}" if days > 0
      end

      res += "#{hours}#{_('h')}#{' ' if session[:user].duration_format == 0}" if hours > 0
    end
    res += "#{minutes}#{_('m')}" if minutes > 0 || res == ''

    if( session[:user].duration_format == 2 )
      res = if weeks > 0
              format("%d:%d:%d:%02d", weeks, days, hours, minutes)
            elsif days > 0
              format("%d:%d:%02d", days, hours, minutes)
            else
              format("%d:%02d", hours, minutes)
            end
    elsif( session[:user].duration_format == 3 )
      res = format("%d:%02d", (weeks * 60 * 8 * 5) + (days * 60 * 8) + hours, minutes)
    end

    res.strip
  end


  def total_today
    @logs = WorkLog.find(:all, :conditions => ["user_id = ? AND started_at > ? AND started_at < ?", session[:user].id, tz.local_to_utc(Time.now.at_midnight), tz.local_to_utc(Time.now.tomorrow.at_midnight)])
    total = 0
    @logs.each { |l|
    total = total + l.duration
    }

    if session[:sheet] && sheet = Sheet.find(:first, :conditions => ["user_id = ? AND task_id = ?", session[:user].id, session[:sheet].task.id])
      total = total + ((Time.now.utc - sheet.created_at) / 60).to_i
    end

    total
  end

  def due_time(from_time, to_time = 0)
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    to_time = to_time.to_time if to_time.respond_to?(:to_time)
    distance_in_minutes = (((to_time - from_time).abs)/60).round

    case distance_in_minutes
    when 0..1440     then _('today')
    when 1441..2880   then _('tomorrow')
    when 2881..10080  then _("%d day", (distance_in_minutes / 1440).round)
    when 10081..20160 then _("%d day", (distance_in_minutes / 1440).round)
    when 20161..43200 then _("%d week", (distance_in_minutes / 1440 / 7).round)
    when 43201..86400 then _("%d month", 1)
    else _("%d month", (distance_in_minutes / 1440 / 30).round)
    end

  end

  def overdue_time(from_time, to_time = 0)
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    to_time = to_time.to_time if to_time.respond_to?(:to_time)
    distance_in_minutes = (((to_time - from_time).abs)/60).round

    case distance_in_minutes
    when 0..1440     then _('yesterday')
    when 1441..10080  then _("%d day ago", (distance_in_minutes / 1440).round)
    when 10081..20160 then _('%d week ago', 1)
    when 20161..43200 then _("%d week ago", (distance_in_minutes / 1440 / 7).round)
    when 43201..86400 then _("%d month ago", 1)
    else _("%d month ago", (distance_in_minutes / 1440 / 30).round)
    end

  end

  def due_in_words(task)
    res = ""
    css = ""

    due_date = nil
    due_date = task.milestone.due_at unless task.milestone.nil? || task.milestone.due_at.nil?
    due_date = task.due_at unless task.due_at.nil?

    if due_date
      if tz.utc_to_local(due_date) > tz.now
        res = due_time( tz.now, tz.utc_to_local(due_date) )
        if (tz.utc_to_local(due_date) - tz.now) > 7.days
          css = "due_distant"
        elsif (tz.utc_to_local(due_date) - tz.now) >= 2.days
          css = "due_soon"
        elsif (tz.utc_to_local(due_date) - tz.now) >= 1.days
          css = "due_tomorrow"
        else
          css = "due"
        end
      else
        res = overdue_time( tz.now, tz.utc_to_local(due_date) )
        css = "due_overdue"
      end
    end

    if res.length > 0
      res = "<span class=\"" + css + "\">[" + res + "]</span>"
    end
  end

  def due_in_css(task)
    css = ""

    due_date = nil
    due_date = task.milestone.due_at unless task.milestone.nil? || task.milestone.due_at.nil?
    due_date = task.due_at unless task.due_at.nil?

    if due_date
      if tz.utc_to_local(due_date) > tz.now
        if (tz.utc_to_local(due_date) - tz.now) > 7.days
          css = "due_distant"
        elsif (tz.utc_to_local(due_date) - tz.now) >= 2.days
          css = "due_soon"
        elsif (tz.utc_to_local(due_date) - tz.now) >= 1.days
          css = "due_tomorrow"
        else
          css = "due"
        end
      else
        css = "due_overdue"
      end
    end
    css
  end


  def activity_img(activity)
    case activity.activity_type
    when Activity::TASK_COMPLETED then image_tag("completed.gif")
    when Activity::TASK_NOT_COMPLETED then image_tag("reverted.png")
    when Activity::TASK_CREATED then image_tag("new_task.png")
    when Activity::TASK_DELETED then image_tag("delete_task.gif")
    when Activity::COMPONENT_CREATED then "Component" + image_tag("new_task.png")
    when Activity::COMPONENT_DELETED then "Component" + image_tag("delete_task.gif")

    when Activity::PAGE_CREATED then "Page Added"
    when Activity::PAGE_MODIFIED then "Page Modified"
    when Activity::PAGE_RENAMED then "Page Renamed"
    when Activity::PAGE_DELETED then "Page Deleted"

    when Activity::FILE_UPLOADED then "File Uploaded"
    when Activity::FILE_DELETED then "File Deleted"


    else "Unknown"
    end
  end



    # Returns HTML code for a calendar that pops up when the calendar image is
  # clicked.
  #
  # _Example:_
  #
  #  <%= popup_calendar 'person', 'birthday',
  #        { :class => 'date',
  #          :field_title => 'Birthday',
  #          :button_image => 'calendar.gif',
  #          :button_title => 'Show calendar' },
  #        { :firstDay => 1,
  #          :range => [1920, 1990],
  #          :step => 1,
  #          :showOthers => true,
  #          :cache => true }
  #  %>
  #
  def popup_calendar(object, method, html_options = {}, calendar_options = {})
    _calendar(object, method, false, true, html_options, calendar_options)
  end

  # Returns HTML code for a flat calendar.
  #
  # _Example:_
  #
  #  <%= calendar 'person', 'birthday',
  #        { :class => 'date' },
  #        { :firstDay => 1,
  #          :range => [1920, 1990],
  #          :step => 1,
  #          :showOthers => true }
  #  %>
  #
  def flat_calendar(object, method, html_options = {}, calendar_options = {})
    _calendar(object, method, false, false, html_options, calendar_options)
  end

  # Returns HTML code for a date field and calendar that pops up when the
  # calendar image is clicked.
  #
  # _Example:_
  #
  #  <%= calendar_field 'person', 'birthday',
  #        { :class => 'date',
  #          :field_title => 'Birthday',
  #          :button_title => 'Show calendar' },
  #        { :firstDay => 1,
  #          :range => [1920, 1990],
  #          :step => 1,
  #          :showOthers => true,
  #          :cache => true }
  #  %>
  #
  def calendar_field(object, method, html_options = {}, calendar_options = {})
    _calendar(object, method, true, true, html_options, calendar_options)
  end

  def _calendar(object, method, show_field = true, popup = true, html_options = {}, calendar_options = {})
    button_image = html_options[:button_image] || 'calendar.png'
    date = value(object, method)

    input_field_id = "#{object}_#{method}"
    calendar_id = "#{object}_#{method}_calendar"

    add_defaults(calendar_options, :ifFormat => '%Y/%m/%d %H:%M:%S')

    field_options = html_options.dup
    add_defaults(field_options,
      :value => date && date.strftime(calendar_options[:ifFormat]),
      :size => 12
    )
    rename_option(field_options, :field_title, :title)
    remove_option(field_options, :button_title)
    if show_field
      field = text_field(object, method, field_options)
    else
      field = hidden_field(object, method, field_options)
    end

    if popup
      button_options = html_options.dup
      add_mandatories(button_options, :id => calendar_id)
      rename_option(button_options, :button_title, :title)
      remove_option(button_options, :field_title)
      remove_option(button_options, :size)
      calendar = image_tag(button_image, button_options)
    else
      calendar = "<div id=\"#{calendar_id}\" class=\"#{html_options[:class]}\"></div>"
    end

    calendar_setup = calendar_options.dup
    add_mandatories(calendar_setup,
      :inputField => input_field_id,
      (popup ? :button : :flat) => calendar_id
    )

    "#{field}#{calendar}<script type=\"text/javascript\">  Calendar.setup({ #{format_js_hash(calendar_setup)} })</script>"

  end

  def value(object_name, method_name)
    if object = self.instance_variable_get("@#{object_name}")
      object.send(method_name)
    else
      nil
    end
  end

  def add_mandatories(options, mandatories)
    options.merge!(mandatories)
  end

  def add_defaults(options, defaults)
    options.merge!(defaults) { |key, old_val, new_val| old_val }
  end

  def remove_option(options, key)
    options.delete(key)
  end

  def rename_option(options, old_key, new_key)
    if options.has_key?(old_key)
      options[new_key] = options.delete(old_key)
    end
    options
  end

  def format_js_hash(options)
    options.collect { |key,value| key.to_s + ':' + value.inspect }.join(',')
  end

  def split_str(str=nil, len=10, char=" ")
    len = 10 if len < 1
    work_str = str.to_s.split(//) if str
    return_str = ""
    i = 0
    if work_str
      work_str.each do |s|
        if (s == char || i == len)
          return_str += char
          return_str += s if s != char
          i = 0
        else
          return_str += s
          i += 1
        end
      end
    end
    return_str
  end


  def wrap_text(txt, col = 80)

    txt.gsub!(/(.{1,#{col}})( +|$)\n?|(.{#{col}})/, "\\1\\3\n")
    txt.gsub!(/#([0-9]+)/, "<a href=\"/tasks/view/\\1\">#\\1</a>")
    txt.gsub( WikiRevision::WIKI_LINK ) { |m|
      match = m.match(WikiRevision::WIKI_LINK)
      name = text = match[1]

      alias_match = match[1].match(WikiRevision::ALIAS_SEPARATION)
      if alias_match
        name = alias_match[1]
        text = alias_match[2]
      end

      if name.downcase.include? '://'
        url = name
      else
        url = "/wiki/show/#{URI.encode(name)}"
      end

      "<a href=\"#{url}\">#{text}</a>"
    }


  end

  def highlight_all( text, keys )
    keys.each do |k|
      text = highlight(text, k)
    end
    text
  end

  def in_progress(task, text )
    if task.status == 1
      "<em>#{text}</em>"
    else
      text
    end
  end

end
