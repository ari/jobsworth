# encoding: UTF-8
# The methods added to this helper will be available to all templates in the application.

module ApplicationHelper
  def current_pages
    @pages ||= current_user.company.pages.projects.where("notable_id in (?)", current_project_ids)
  end

  def total_today
    return @total_today if @total_today
    @total_today = 0
    start = tz.local_to_utc(tz.now.at_midnight)
    @total_today = current_user.work_logs.where("started_at > ? AND started_at < ?", start, start + 1.day).sum(:duration).to_i / 60

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
    when 2881..20160  then _("%d days", (distance_in_minutes / 1440).round)
    when 20161..43200 then _("%d weeks", (distance_in_minutes / 1440 / 7).round)
    when 43201..86400 then _("%d month", 1)
    else _("%d months", (distance_in_minutes / 1440 / 30).round)
    end

  end

  def overdue_time(from_time)
    _('%s ago', time_ago_in_words( from_time, false))
  end

  def due_in_words(task)
    res = ""
    css = due_in_css(task)

    due_date = task.due_date
    if due_date
      local_due = tz.utc_to_local(due_date)
      tz_now = tz.now
      if local_due > tz_now
        res = due_time( tz_now, local_due )
      else
        res = overdue_time( local_due )
      end
    end

    if res.length > 0
      res = "<span class=\"#{css}\">#{res}</span>"
    end

    return res.html_safe
  end

  def due_in_css(task)
    css = ""
    return css if task.resolved?
    due_date= task.due_date
    if due_date
      local_due = tz.utc_to_local(due_date)
      tz_now = tz.now
      if local_due > tz_now
        if (local_due - tz_now) > 7.days
          css = "due_distant"
        elsif (local_due - tz_now) >= 2.days
          css = "due_soon"
        elsif (local_due - tz_now) >= 1.days
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

  def wrap_text(txt)
    txt.gsub!(/#([0-9]+)/, "<a href=\"/tasks/view/\\1\">#\\1</a>")
    txt.gsub!(/([\w\.\-\+]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})/i, '<a href="mailto:\\0">\\0</a>')
    txt.gsub!(/(http\S+(?:gif|jpg|png))(\?.*)?/i, "<a href=\"\\0\" target=\"blank\">\\0</a>")
    txt.gsub!(URI.regexp) { |m|
      elems = m.match(URI.regexp).to_a
      "<a href=\"#{elems[0]}\" target=\"_blank\">".html_safe + elems[0] + "</a>".html_safe
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

      "<a href=\"#{url}\">".html_safe + text + "</a>".html_safe
    }
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
   open= current_user.company.statuses.first
   link_to(h(milestone.name), path_to_tasks_filtered_by(milestone, open),{
     :class => "#{milestone_classes(milestone)}",
     :rel => "tooltip",
     "data-placement" => "right",
     :title => milestone.to_tip(:duration_format => current_user.duration_format, :workday_duration => current_user.workday_duration, :days_per_week => current_user.days_per_week, :user => current_user)} )
  end

  def submit_tag(value = "Save Changes", options={} )
    or_option = options.delete(:or)
    return super + ("<span class='button_or'>"+"or"+" " + or_option + "</span>").html_safe if or_option
    super
  end

  def ajax_spinner_for(id, spinner="spinner.gif")
    "<img src='/images/#{spinner}' style='display:none; vertical-align:middle;' id='#{id.to_s}_spinner'> ".html_safe
  end

  def avatar_for(user, size=32)
    if current_user.option_avatars == 1
      return "<img src=\"#{user.avatar_url(size, request.ssl?)}\" class=\"photo\" />".html_safe
    end
    ""
  end


  def feed_icon_tag(title, url)
    #(@feed_icons ||= []) << { :url => url, :title => title }
    #link_to image_tag('feed-icon.png', :size => '14x14', :alt => "Subscribe to #{title}"), url
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

    return image_tag(File.join("icons", src), :rel => "tooltip", :alt => pv, :title => pv) if !src.blank?
  end

  ##
  # Return the options html for task icons selection.
  ##
  def task_icon_options(pv)
    arr = []
    Dir.chdir(File.join(Rails.root.to_s, "app", "assets", "images", "icons")) do
      arr = Dir.glob("*.{png,gif,jpg}")
    end

    arr.map! {|icon| [icon, icon]}
    arr.insert(0, ["none", ""])
    options_for_select(arr, pv.icon_url)
  end

  ###
  # Returns a submit tag suitable for the given object.
  # (Create or Update)"
  ###
  def cit_submit_tag(object)
    text = object.new_record? ? _("Create") : _("Save")
    submit_tag(text, :class => 'btn btn-primary')
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
    link_to('<i class="icon-remove"></i>'.html_safe, "#", {:id=> "link_to_remove_patent"} )
  end

  ###
  # Returns the html class to use for the tab menu.
  ###
  def menu_class(resource)
    name = controller.controller_name
    return "active" if name == resource
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
    if @task and @task.project_id.to_i > 0
      selected_project = @task.project_id
    else
      selected_project = current_user.projects.order('name').first.id
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

    return res.html_safe
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

  # return links to edit current task  templates
  def template_links
    current_templates.collect do |t|
      link_to t, :controller=>'task_templates', :action=>'edit',:id=>t.task_num
    end
  end

  def escape_twice(attr)
    h(String.new(h(attr)))
  end

  def grouped_client_projects_options(projects)
    last_customer = nil
    options = []

    projects.each do |project|
      if project.customer != last_customer
        options << [ h(project.customer.name), [] ]
        last_customer = project.customer
      end

      options.last[1] << [ project.name, project.id ]
    end
    return options
  end
end



