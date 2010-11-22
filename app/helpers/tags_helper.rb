# encoding: UTF-8
module TagsHelper

# Returns links to filter the current task list by tags
  def tag_links
    links = []
    tags = Tag.top_counts_as_tags(current_user.company, current_user.user_tasks_sql+"AND tasks.completed_at is NULL")
    ranges = cloud_ranges(tags.map { |tag, count| count })

    tags.each do |tag, count|
      value = ranges.detect { |r| r > count }
      range = ranges.index(value)
      range ||= ranges.length
      class_name = "size#{ range }"

      links << link_to_filter_on_tag(tag, :class => class_name)
    end

    return links.join(", ").html_safe
  end

  # Returns a link to view tasks with the given tag.
  # Anything passed in options will be passed to the link_to call.
  def link_to_filter_on_tag(tag,  options = {})
      open = current_user.company.statuses.first
      return link_to(h(tag.name), path_to_tasks_filtered_by(tag, open), options)
  end
end
