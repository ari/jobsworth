# The methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  require_dependency 'digest/md5'

  URL_MATCH = /(https?):\/\/(([-\w\.]+)+(:\d+)?(\/([\w%\/_\.-:\+]*(\?\S+)?)?)?)/i

  include Misc

  def online_users
    current_users.size
  end

  def user_online?(user_id)
    c = User.count( :conditions => "id = #{user_id} AND last_ping_at > '#{2.minutes.ago.utc.to_s(:db)}' AND company_id=#{current_user.company_id}" ) > 0
  end

  def user_name
    current_user.name
  end

  def company_name
    current_user.company.name
  end

  def current_pages
    pages = Page.find(:all, :order => 'updated_at, name', :conditions => [ "company_id = ? AND project_id IN (#{current_project_ids})", current_user.company_id ] )
  end

  def urlize(name)
    name.to_s.gsub(/ /, "-").downcase
  end

  def total_today
    return @total_today if @total_today
    @total_today = 0
    start = tz.local_to_utc(tz.now.at_midnight)
    @total_today = WorkLog.sum(:duration, :conditions => ["user_id = ? AND started_at > ? AND started_at < ?", current_user.id, start, start + 1.day]).to_i / 60
    
    @total_today += @current_sheet.duration / 60 if @current_sheet
    @total_today
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

  def overdue_time(from_time)
    _('%s ago', time_ago_in_words( from_time, false))
  end

  def due_in_words(task)
    res = ""
    css = ""

    due_date = task.due_date
    
    if due_date
      utc_due = tz.utc_to_local(due_date)
      tz_now = tz.now
      if utc_due > tz_now
        res = due_time( tz_now, utc_due )
        if (utc_due - tz_now) > 7.days
          css = "due_distant"
        elsif (utc_due - tz_now) >= 2.days
          css = "due_soon"
        elsif (utc_due - tz_now) >= 1.days
          css = "due_tomorrow"
        else
          css = "due"
        end
      else
        res = overdue_time( utc_due )
        css = "due_overdue"
      end
    end

    if task.repeat && task.repeat.length > 0
      res += ", " + task.repeat_summary
    end

    if res.length > 0
      res = "<span class=\"#{css}\">[#{res}]</span>"
    end
  end

  def due_in_css(task)
    css = ""

    due_date = nil
    due_date = task.milestone.due_at unless task.milestone.nil? || task.milestone.due_at.nil?
    due_date = task.due_at unless task.due_at.nil?

    if due_date
      utc_due = tz.utc_to_local(due_date)
      tz_now = tz.now
      if utc_due > tz_now
        if (utc_due - tz_now) > 7.days
          css = "due_distant"
        elsif (utc_due - tz_now) >= 2.days
          css = "due_soon"
        elsif (utc_due - tz_now) >= 1.days
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
      :value => date && date.strftime_localized(calendar_options[:ifFormat]),
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
#      calendar = image_tag(button_image, :id => calendar_id)
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

    txt.chars.gsub!(/(.{1,#{col}})( +|$)\n?|(.{#{col}})/, "\\1\\3\n")
    txt.gsub!(/#([0-9]+)/, "<a href=\"/tasks/view/\\1\">#\\1</a>")
    txt.gsub!(/([\w\.\-\+]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})/i, '<a href="mailto:\\0">\\0</a>')
    txt.gsub!(/(http\S+(?:gif|jpg|png))(\?.*)?/i, "<a href=\"\\0\" target=\"blank\"><img src=\"\\0\" border=\"0\" onload=\"inline_image(this);\"/></a>")
    txt.gsub!(URL_MATCH) {|m|
      if(m.match(/\.(jpe?g|gif|png)/))
        m
      else
        elems = m.match(URL_MATCH).to_a
        "<a href=\"#{elems[0]}\" target=\"_blank\">#{elems[0]}</a>"
      end
    }

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

  def link_to_task(task)
    "<strong>#{task.issue_num}</strong> <a href=\"/tasks/edit/#{task.id}\" class=\"tooltip#{task.css_classes}\" title=\"#{task.to_tip({ :duration_format => current_user.duration_format, :workday_duration => current_user.workday_duration, :days_per_week => current_user.days_per_week, :user => current_user })}\">#{h(task.name.chars[0..80])}</a>"
  end

  def link_to_task_with_highlight(task, keys)
    "<strong>#{task.issue_num}</strong> " + link_to( highlight_all(h(task.name), keys), {:controller => 'tasks', :action => 'edit', :id => task.id}, {:class => "tooltip#{task.css_classes}", :title => highlight_all(task.to_tip({ :duration_format => current_user.duration_format, :workday_duration => current_user.workday_duration, :days_per_week => current_user.days_per_week, :user => current_user }), keys)})
  end

  def milestone_classes(m)
    return " complete_milestone" unless m.completed_at.nil?

    unless m.due_at.nil?
      if m.due_at.utc < Time.now.utc
        return " overdue_milestone"
      end
    end
    ""
  end

  def link_to_milestone(milestone)
    link_to( h(milestone.name), {:controller => 'views', :action => 'select_milestone', :id => milestone.id}, {:class => "tooltip#{milestone_classes(milestone)}", :title => milestone.to_tip(:duration_format => current_user.duration_format, :workday_duration => current_user.workday_duration, :days_per_week => current_user.days_per_week, :user => current_user)})
  end

  def submit_tag(value = "Save Changes", options={} )
    or_option = options.delete(:or)
    return super + "<span class='button_or'>"+"or"+" " + or_option + "</span>" if or_option
    super
  end

  def ajax_spinner_for(id, spinner="spinner.gif")
    "<img src='/images/#{spinner}' style='display:none; vertical-align:middle;' id='#{id.to_s}_spinner'> "
  end

  def avatar_for(user, size=32)
    if current_user.option_avatars == 1
      return "<img src=\"#{user.avatar_url(size, request.ssl?)}\" class=\"photo\" />"
    end
    ""
  end


  def feed_icon_tag(title, url)
    #(@feed_icons ||= []) << { :url => url, :title => title }
    #link_to image_tag('feed-icon.png', :size => '14x14', :alt => "Subscribe to #{title}"), url
  end

  def search_posts_title
    returning(params[:q].blank? ? 'Recent Posts' : "Searching for" + " '#{h params[:q]}'") do |title|
      title << " "+'by ' + h(User.find(params[:user_id]).display_name) if params[:user_id]
      title << " "+'in ' + h(Forum.find(params[:forum_id]).name) if params[:forum_id]
    end
  end

  def topic_title_link(topic, options)
    if topic.title =~ /^\[([^\]]{1,15})\]((\s+)\w+.*)/
      "<span class='flag'>#{$1}</span>" +
      link_to(h($2.strip), topic_path(@forum, topic), options)
    else
      link_to(h(topic.title), topic_path(@forum, topic), options)
    end
  end

  def search_posts_path(rss = false)
    options = params[:q].blank? ? {} : {:q => params[:q]}
    prefix = rss ? 'formatted_' : ''
    options[:format] = 'rss' if rss
    [[:user, :user_id], [:forum, :forum_id]].each do |(route_key, param_key)|
      return send("#{prefix}#{route_key}_posts_path", options.update(param_key => params[param_key])) if params[param_key]
    end
    options[:q] ? all_search_posts_path(options) : send("#{prefix}all_posts_path", options)
  end

  def admin?
    current_user.admin > 0
  end

  def logged_in?
    true
  end


# def time_ago_or_time_stamp(from_time, to_time = Time.now, include_seconds = true, detail = false)
#   [from_time, to_time].each {|t| t = t.to_time if t.respond_to?(:to_time)}
#   if (((to_time - from_time).abs)/60).round > 2880 && detail
#     return timestamp(from_time)
#   else
#     return distance_of_time_in_words(from_time, to_time, include_seconds)
#   end
# end

  def has_popout?(t)
    if t.is_a? Task
      (@current_sheet && @current_sheet.task_id == t.id) || t.done?
    end
  end



  def flash_plugin(channels = ["default"])
    config = Juggernaut.config
    host = request.server_name
    port = config["PUSH_PORT"]
#  crossdomain = config["CROSSDOMAIN"]
#  juggernaut_data =  CGI.escape('"' + channels.join('","') + '"')

<<-"END_OF_HTML"
<script type="text/javascript">
new Juggernaut({ host:'#{host}', port: #{port}, channels:["#{channels.join('","')}"], sounds: #{current_user.enable_sounds?} });
</script>
END_OF_HTML
  end


  def use_tinymce
    @content_for_tinymce = "" 
    content_for :tinymce do
      javascript_include_tag "tiny_mce/tiny_mce"
    end
    @content_for_tinymce_init = "" 
    content_for :tinymce_init do
      javascript_include_tag "tiny_mce"
    end
  end

end


