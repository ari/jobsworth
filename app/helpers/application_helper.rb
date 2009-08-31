# The methods added to this helper will be available to all templates in the application.
require 'digest/md5'

module ApplicationHelper
  URL_MATCH = /(https?):\/\/(([-\w\.]+)+(:\d+)?(\/([\w%\/_\.-:\+]*(\?\S+)?)?)?)/i

  include Misc

  def online_users
    current_users.size
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

    if task.repeat && task.repeat.length > 0 && !task.repeat_summary.nil?
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

#   def link_to_task(task)
#     "<strong>#{task.issue_num}</strong> <a href=\"/tasks/edit/#{task.task_num}\" class=\"tooltip#{task.css_classes}\" title=\"#{task.to_tip({ :duration_format => current_user.duration_format, :workday_duration => current_user.workday_duration, :days_per_week => current_user.days_per_week, :user => current_user })}\">#{h(truncate(task.name, :length => 80))}</a>"
#   end

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

  ###
  # Returns a string of css style to color task using the
  # selected (in the session) coloring.
  ###
  def color_style(task)
    color_property = session[:colors].to_i

    if color_property > 0
      property = current_user.company.properties.detect { |p| p.id == color_property }
    else 
      property = current_user.company.properties.detect { |p| p.default_color }
    end

    value = task.property_value(property)
    if value
      return "border-left: 4px solid #{ value.color }; background: none;"
    end
  end

  ###
  # Return an html tag to display the icon for given task using
  # the selected (in the session) icons to display.
  ###
  def task_icon(task)
    icon_property = session[:icons].to_i
    
    property = current_user.company.type_property
    if icon_property != 0 and !property
      property = current_user.company.properties.detect { |p| p.id == icon_property }
    end

    pv = task.property_value(property)
    src = pv.icon_url if pv

    return image_tag(src, :class => "tooltip", :alt => pv, :title => pv) if !src.blank?
  end

  ###
  # Returns true if the current user can organize tasks based
  # on the their rights.
  ###
  def can_organize?
    can = false
    group_by = session[:group_by]
    if group_by.to_i > 2 and @tasks
      gb = group_by.to_i
      affected_projects = @tasks.flatten.collect(&:project).uniq
      can = case gb
            when 3  then current_user.can_all?(affected_projects, 'reassign')
            when 4  then current_user.can_all?(affected_projects, 'reassign')
            when 5  then current_user.can_all?(affected_projects, 'reassign')
            when 6  then current_user.can_all?(affected_projects, 'prioritize')
            when 7  then current_user.can_all?(affected_projects, 'close')
            when 8  then current_user.can_all?(affected_projects, 'prioritize')
            when 9  then current_user.can_all?(affected_projects, 'prioritize')
            when 10 then current_user.can_all?(affected_projects, 'reassign')
            end
    elsif Property.find_by_group_by(current_user.company, group_by)
      can = true
    end        

    return can
  end

  ###
  # Returns the html for lis and links for the different task views.
  ###
  def task_view_links
    links = []
    links << [ "List", { :controller => "tasks", :action => "list" } ]
    links << [ "Schedule", { :controller => "schedule", :action => "list" } ]
    links << [ "Gantt", { :controller => "schedule", :action => "gantt" } ]
    links << [ "List (old)", { :controller => "tasks", :action => "list_old" } ]

    res = ""
    links.each_with_index do |opts, i|
      name, url_opts = opts
      link = link_to(name, url_opts)
      class_names = []
      class_names << "first" if i == 0
      class_names << "last" if i == links.length - 1
      class_names << "active" if params.merge(url_opts) == params

      res += content_tag(:li, link, :class => class_names.join(" "))
    end

    return res
  end

  ###
  # Returns a submit tag suitable for the given object.
  # (Create or Update)"
  ###
  def cit_submit_tag(object)
    text = object.new_record? ? _("Create") : _("Save")
    submit_tag(text, :class => 'nolabel')
  end

  ###
  # Returns an element to use a handle for sorting the given
  # object.
  ###
  def sortable_handle_tag(object)
    class_name = "handle #{ object.class.name.underscore }"
    image = image_tag("move.gif", :border => 0, :alt => "#{ _("Move") }", :class => class_name)

    object.new_record? ? "" : image
  end

  ###
  # Returns an element that can be used to remove the parent element from the page. 
  ###
  def link_to_remove_parent
    image = image_tag("cross_small.png", :border => 0, :alt => "#{ _("Remove") }")
    link_to_function(image, 'jQuery(this).parent().remove();')
  end

  ###
  # Returns the html class to use for the resources tab menu.
  ###
  def resource_class
    name = controller.controller_name
    return "active" if name == "resources"
  end

  ###
  # Returns the html to use to display a filter for the given 
  # method, etc
  ###
  def filter_for(meth, names_and_ids, session_filters, label = nil)
    label ||= _(meth.to_s.humanize.titleize)
    default = _('[Any %s', label)

    session_filters ||= {}
    selected = session_filters[meth] || []
    selected = names_and_ids.select { |name, id| selected.include?(id.to_s) }

    res = query_menu("filter[#{ meth }]", names_and_ids, label)
    res += selected_filter_values("filter[#{ meth }]", selected, label)

    return res
  end

  ###
  # Returns the project id that should be selected based on the current 
  # session and filters.
  ### 
  def selected_project
    if @task and @task.project_id > 0
      selected_project = @task.project_id
    else
      selected_project = current_user.projects.find(:first, :order => 'name').id
    end
  

    return selected_project
  end

  ###
  # Returns the html to show pagination links for the given
  #  array.
  ###
  def pagination_links(objects, count = 100)
    will_paginate(objects, {
                    :per_page => count,
                    :next_label => _('Next') + ' &raquo;', 
                    :prev_label => '&laquo; ' + _('Previous')
                  })
  end

    ###
  # Returns the title for the given log. If the log has no title,
  # creates a sensible one.
  # If the log has a target, tries to link to that targets page.
  ###
  def log_title_for(log)
    title = log.title
    title ||= "#{ log.target.class.name.humanize } - #{ log.target }"

    if log.target and log.target.respond_to?(:to_url)
      title = link_to(title, log.target.to_url)
    end

    return title
  end

  ###
  # Returns the html to show a choice field for field called name.
  # Ideally, this would use a checkbox, but checkboxes seem to be 
  # confusing the arrays in the params that rails gets, so using
  # a select for now.
  ###
  def nested_boolean_choice_field(form, name, attribute, opts = {})
    on_change = (attribute.new_record? ? "nestedCheckboxChanged(this)" : nil)
    class_name = (attribute.new_record? ? "nested_checkbox" : nil)

    if opts[:onchange] and on_change
      on_change += "; #{ opts[:onchange] }"
    end

    opts[:class] = "#{ opts[:class] }  #{ class_name }"

    options = opts.merge({ :onchange => on_change, :index => attribute.id })
    return form.check_box(name, options)
  end

  ###
  # Returns the html to display add/remove links for the given attribute value.
  # If the value isn't a multi type, returns nothing.
  ###
  def multi_links(custom_attribute_value)
    res = ""
    value = custom_attribute_value
    attr = value.custom_attribute

    if attr.multiple?
      same_type = (attr == @last_type)
      @last_type = attr

      add_style = same_type ? "display: none" : ""
      remove_style = same_type ? "" : "display: none;"
      
      res += link_to_function(_("Add another"), "addAttribute(this)", 
                                :class => "add_attribute", 
                                :style => add_style) 
      res += link_to_function(_("Remove"), "removeAttribute(this)", 
                              :class => "remove_attribute", 
                              :style => remove_style)
    end

    return res
  end


  # Returns a string to use as the field id for the current
  # custom attribute edit field
  # A new id will be generated each call to this method, so store
  # it if you need to use it in more than one place
  def custom_attribute_field_id
    @ca_field_id ||= 0
    @ca_field_id += 1

    return "custom_attribute_#{ @ca_field_id }"
  end

end



