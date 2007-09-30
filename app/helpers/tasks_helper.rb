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

end
