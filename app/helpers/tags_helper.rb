module TagsHelper

# Returns links to filter the current task list by tags
  def tag_links
    links = []
    tags = Tag.top_counts_as_tags(current_user.company, current_user.user_tasks_sql)
    ranges = cloud_ranges(tags.map { |tag, count| count })
	
    tags.each do |tag, count|
      value = ranges.detect { |r| r > count }
      range = ranges.index(value)
      range ||= ranges.length
      class_name = "size#{ range }"

      links << link_to_filter_on_tag(tag, :class => class_name)
    end

    return links.join(", ")
  end

  # Returns a link to view tasks with the given tag.
  # Anything passed in options will be passed to the link_to call. 
  def link_to_filter_on_tag(tag, options = {})
      str = "#{ tag.name }"
      link_params = {
        :qualifiable_id => tag.id,
        :qualifiable_type => tag.class.name
      }

      link_params = { :qualifiers_attributes => [ link_params ] }
      path = update_current_filter_task_filters_path(:task_filter => link_params)
      return link_to(str, path, options)
  end
end
