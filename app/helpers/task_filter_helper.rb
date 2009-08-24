module TaskFilterHelper
  # returns the current task filter (or a new, blank one
  # if none set)
  def task_filter
    session[:task_filter] ||= TaskFilter.new(:user => current_user)
  end

  ###
  # Returns an array of names and ids
  ###
  def objects_to_names_and_ids(collection, options = {})
    defaults = { :name_method => :name }
    options = defaults.merge(options)

    return collection.map do |o| 
      name = o.send(options[:name_method])
      id = o.id
      id = "#{ options[:prefix] }#{ id }" if options[:prefix]

      [ name, id ]
    end
  end

  ###
  # Returns the html to display the selected values in the current filter.
  ###
  def selected_filter_values(name, selected_names_and_ids, label = nil, default_label_text = "Any", &block)
    label ||= name.gsub(/^filter_/, "").titleize
    selected_names_and_ids ||= []

    locals = {
      :selected_names_and_ids => selected_names_and_ids,
      :filter_name => name,
      :all_label => _("[#{ default_label_text } %s]", label),
      :unassigned => TaskFilter::UNASSIGNED_TASKS
    }
    locals[:display_all_label] = (selected_names_and_ids.any? ? "none" : "")

    return render(:partial => "/tasks/selected_filter_values", :locals => locals, &block)
  end

  ###
  # Returns an array containing the name and id of users currently
  # selected in the filter. Handles "unassigned" tasks too.
  ###
  def selected_user_names_and_ids
    res = TaskFilter.filter_user_ids(session).map do |id|
      if id == TaskFilter::UNASSIGNED_TASKS
        [ _("Unassigned"), id ]
      elsif id > 0
        user = current_user.company.users.find(id)
        [ user.name, id ]
      end
    end

    return res.compact
  end

  ###
  # Returns an array containing the name and id of statuses currently
  # selected in the filter. 
  ###
  def selected_status_names_and_ids
    selected = TaskFilter.filter_status_ids(session)
    return available_statuses.select do |name, id|
      selected.include?(id.to_i)
    end
  end
  
  ###
  # Returns an array of statuses that can be used to filter.
  ###
  def available_statuses
    statuses = []
    statuses << [_("Open"), "0"]
    statuses << [_("In Progress"), "1"]
    statuses << [_("Closed"), "2"]
    statuses << [_("Won't Fix"), "3"]
    statuses << [_("Invalid"), "4"]
    statuses << [_("Duplicate"), "5"]
    statuses << [_("Archived"), "-2"]

    return statuses
  end

  def link_to_remove_filter(filter_name, name, value, id)
    res = content_tag :span, :class => "search_filter" do
      hidden_field_tag("#{ filter_name }[]", id) +
        "#{ name }:#{ value }" + 
        link_to_function(image_tag("cross_small.png"), "removeSearchFilter(this)")
    end

    return res
  end

  # Return the html for a remote task filter form tag
  def remote_filter_form_tag
    form_remote_tag(:url => "/filter/update", 
                    :html => { :method => "post", :id => "search_filter_form"},
                    :loading => "showProgress()",
                    :complete => "hideProgress()",
                    :update => "#content")
  end

  # Returns the html/js to make any tables matching selector sortable
  def sortable_table(selector, default_sort)
    column, direction = (default_sort || "").split("_")

    res = javascript_include_tag "jquery.tablesorter.min.js"
    js = <<-EOS
           makeSortable(jQuery("#{ selector }"), "#{ column }", "#{ direction }");
           jQuery("#{ selector }").bind("sortEnd", saveSortParams);
EOS
    res += javascript_tag(js, :defer => "defer")
    return res
  end

end
