module ReportsHelper

  def total_amount_worked(logs)
    total = 0
    for log in logs 
      total += log.duration
    end
    total
  end 

  def total_task_worked(logs, task_id)
    total = 0
    for log in logs
      if log.task.id == task_id
        total += log.duration
      end 
    end 
    total
  end

  ###
  # Returns a select tag to use to choose what to display in
  # the report. name should probably be "rows" or "columns"
  ###
  def display_select(name, default_selected)
    options = [
               [_("Tasks"), "1"],
               [_("Tags"), "2"],
               [_("Users"), "3"],
               [_("Clients"), "4"],
               [_("Projects"), "5"],
               [_("Milestones"), "6"],
               [_("Date"), "7"],
               [_("Task Status"), "8"],
               [_("Requested By"), "20"]
              ]
    current_user.company.properties.each do |p|
      options << [ p.name, p.filter_name ]
    end
    
    if params[:report] and params[:report][name.to_sym]
      selected = params[:report][name.to_sym]
    end

    return select("report", name, options, :selected => (selected || default_selected))
  end

  ###
  # Returns an array of options to use for populating the row and
  # column selects.
  ###

  def options_for_rows_and_columns
    
  end
end
