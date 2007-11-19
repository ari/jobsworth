module TasksHelper

  def pri_color(severity, priority)
    color = "#b0d295"
    color = "#f2ab99" if (priority + severity)/2.0 > 0.5
    color = "#FF6666" if (priority + severity)/2.0 > 1.5
    color = "#e7e0c4" if (priority + severity)/2 < -0.5
    color = "#F3F3F3" if (priority + severity)/2 < -1.5

    " style = \"background-color: #{color};\""

  end

  def print_title
    filters = []
    title = "<div style=\"float:left\">"
    if session[:filter_status].to_i >= 0
      title << Task.status_types[session[:filter_status].to_i] + " tasks ["
    else
      title << "Tasks ["
    end

    if session[:filter_customer].to_i > 0
      filters << Customer.find(session[:filter_customer].to_i).name
    end

    if session[:filter_project].to_i > 0
      filters << Project.find(session[:filter_project].to_i).name
    end

    if session[:filter_user].to_i > 0
      filters << User.find(session[:filter_user].to_i).name
    end

    filters << session[:user].company.name if filters.empty?

    title << filters.join(' / ')

    title << "]</div><div style=\"float:right\">#{tz.now.strftime("#{session[:user].time_format} #{session[:user].date_format}")}</div><div style=\"clear:both\"></div>"

    "<h3>#{title}</h3>"

  end

  def task_shown?(t)

    shown = true

    if session[:filter_status].to_i >= 0
      if session[:filter_status].to_i == 0
        shown = ( t.status == 0 || t.status == 1 ) if shown
      elsif session[:filter_status].to_i == 2
        shown = t.status > 1 if shown
      else
        shown = session[:filter_status].to_i == t.status if shown
      end
    end

    if session[:filter_milestone].to_i > 0 && shown
      shown = session[:filter_milestone].to_i == t.milestone_id if shown
    end

    if session[:filter_customer].to_i > 0 && shown
      shown = session[:filter_customer].to_i == t.project.customer_id if shown
    end

    if session[:filter_project].to_i > 0 && shown
      shown = session[:filter_project].to_i == t.project_id if shown
    end

    if session[:filter_user].to_i > 0 && shown
      shown = t.users.collect(&:id).include?( session[:filter_user].to_i ) if shown
    elsif session[:filter_user].to_i < 0 && shown
      shown = t.users.empty?
    end


    shown
  end

  def render_task_dependants(t, depth, root_present)
    res = ""
    @printed_ids ||= []

    return if @printed_ids.include? t.id

    shown = task_shown?(t)

#    logger.info("#{t.name}[#{shown}]")

    unless root_present
      parents = []
      p = t
      root = nil
      while p.dependencies.size > 0
        p.dependencies.each do |p|
          root = p unless p.done?
        end
        root ||= p.dependencies.first
#        parents << parent
        p = root
        logger.info("New parent[#{p.name}")
      end

      res << render_task_dependants(root, depth, true)

#      parents.reverse.each_with_index do |parent, index|
#        res << render(:partial => "task_row", :locals => { :task => parent, :depth => depth + index + 1, :override_filter => true })
#      end
#      depth = depth + parents.size + 1
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
    res
  end

end
