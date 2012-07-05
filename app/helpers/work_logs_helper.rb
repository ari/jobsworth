# encoding: UTF-8
module WorkLogsHelper
  ###
  # Returns an array to use as the options for a select
  # to change a work log's status.
  ###
  def work_log_status_options
    options = []
    options << [_("Leave Open"), 0] if @task.open?
    options << [_("Revert to Open"), 0] if @task.resolved?
    options << [_("Close"), 1] if @task.open?
    options << [_("Leave Closed"), 1] if @task.closed?
    options << [_("Set as Won't Fix"), 2] if @task.open?
    options << [_("Leave as Won't Fix"), 2] if @task.will_not_fix?
    options << [_("Set as Invalid"), 3] if @task.open?
    options << [_("Leave as Invalid"), 3] if @task.invalid?
    options << [_("Set as Duplicate"), 4] if @task.open?
    options << [_("Leave as Duplicate"), 4] if @task.duplicate?

    return options
  end

  ###
  # Returns a hash to use as the options for the task
  # status dropdown on the work log edit page.
  ###
  def work_log_status_html_options
    options = {}
    options[:disabled] = "disabled" unless current_user.can?( @task.project, "close" )

    return options
  end

  def time_format(format)
    case format
    when "%m/%d/%Y"
      [:month, :day, :year]
    when "%d/%m/%Y"
      [:day,:month,:year]
    when "%Y-%m-%d"
      [:year,:month,:day]
    else
      [:day,:month,:year]
    end
  end

  ##
  # Returns a list of customers/clients that could a log
  # could potentially be attached to
  ##
  def work_log_customer_options(log)
    res = @log.task.customers.clone
    res << @log.task.project.customer if @log.task.project

    res = res.uniq.compact
    return objects_to_names_and_ids(res)
  end

  ##
  # Returns true if the current user can delete the given log
  ##
  def can_delete_log?(log)
    return (!log.new_record? and
            (current_user.admin? || log.user == current_user))
  end

end
