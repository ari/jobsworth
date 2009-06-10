###
# Worklog Reports are ways of viewing worklogs. They can be used
# as a timesheet, audit, etc
###
class WorklogReport
  ###
  # A sorted array of worklogs that match the setup 
  # for this report.
  ###
  attr_reader :work_logs

  ###
  # An int representing the type of this report (TIMESHEET, WORKLOAD, etc)
  ###
  attr_reader :type

  ###
  # The timezone of the report
  ###
  attr_reader :tz

  attr_reader :start_date
  attr_reader :end_date

  TIMESHEET = 3
  WORKLOAD = 4

  ###
  # Creates a report for the given tasks and params
  ###
  def initialize(controller, params)
    task_filter = TaskFilter.new(controller, controller.session)
    tasks = task_filter.tasks

    @tz = controller.tz
    @type = params[:type].to_i

    init_start_and_end_dates(params)
    init_work_logs(tasks)
  end

  ###
  # Calculates and returns the date range of the work logs
  ###
  def range
    # Swap to an appropriate range based on entries returned
    start_date = self.start_date
    end_date = self.end_date

    for w in work_logs
      start_date = tz.utc_to_local(w.started_at) if(start_date.nil? || (tz.utc_to_local(w.started_at) < start_date))
      end_date = tz.utc_to_local(w.started_at) if(end_date.nil? || (tz.utc_to_local(w.started_at) > end_date))
    end

    range = nil
    if start_date && end_date
      days = end_date - start_date
      if days <= 1.days
        range = 0
      elsif days <= 7.days
        range = 1
      elsif days <= 31.days
        range = 3
      else
        range = 5
      end
    end

    return range
  end

  private

  ###
  # Set up the start and end date for work logs to be included.
  ###
  def init_start_and_end_dates(params)
    range = params[:range].to_i
    case range
    when 0
      # Today
      @start_date = tz.local_to_utc(tz.now.at_midnight)
    when 8
      # Yesterday
      @start_date = tz.local_to_utc((tz.now - 1.day).at_midnight)
      @end_date = tz.local_to_utc(tz.now.at_midnight)
    when 1
      # This Week
      @start_date = tz.local_to_utc(tz.now.beginning_of_week)
    when 2
      # Last Week
      @start_date = tz.local_to_utc((tz.now - 1.week).beginning_of_week)
      @end_date = tz.local_to_utc(tz.now.beginning_of_week)
    when 3
      # This Month
      @start_date = tz.local_to_utc(tz.now.beginning_of_month)
    when 4
      # Last Month
      @start_date = tz.local_to_utc(tz.now.last_month.beginning_of_month)
      @end_date = tz.local_to_utc(tz.now.beginning_of_month)
    when 5
      # This Year
      @start_date = tz.local_to_utc(tz.now.beginning_of_year)
    when 6
      # Last Year
      @start_date = tz.local_to_utc(tz.now.last_year.beginning_of_year)
      @end_date = tz.local_to_utc(tz.now.beginning_of_year)
    when 7
      if params[:start_date] && params[:start_date].length > 1
        begin
          start_date = DateTime.strptime( filter[:start_date], current_user.date_format ).to_time 
        rescue
          flash['notice'] ||= _("Invalid start date")
          start_date = tz.now
        end

        @start_date = tz.local_to_utc(start_date.midnight)
      end

      if filter[:stop_date] && filter[:stop_date].length > 1
        begin
          end_date = DateTime.strptime( filter[:stop_date], current_user.date_format ).to_time 
        rescue 
          flash['notice'] ||= _("Invalid end date")
          end_date = tz.now
        end 

        @end_date = tz.local_to_utc((end_date + 1.day).midnight)
      end
    end
  end

  ###
  # Setup the @work_logs var with any work logs from 
  # tasks which should be shown for this report.
  ###
  def init_work_logs(tasks)
    logs = []

    tasks.each do |t|
      if @type == WORKLOAD
        logs += work_logs_for_workload(t)
      else
        logs += t.work_logs
      end
    end

    logs = logs.select do |log|
      (@start_date.nil? or log.started_at >= @start_date) and
        (@end_date.nil? or log.started_at <= @end_date)
    end

    @work_logs = logs.sort_by { |log| log.started_at }
  end

  ###
  # Returns work logs that should be shown for the
  # given task in a workload report
  ###
  def work_logs_for_workload(t)
    res = []

    if t.users.size > 0
      t.users.each do |u|
        w = WorkLog.new
        w.task = t
        w.user_id = u.id
        w.company = t.company
        w.customer = t.project.customer
        w.project = t.project
        w.started_at = (t.due_at ? t.due_at : (t.milestone ? t.milestone.due_at : tz.now) )
        w.started_at = tz.now if w.started_at.nil? || w.started_at.to_s == ""
        w.duration = t.duration.to_i * 60
        res << w
      end
    else
      w = WorkLog.new
      w.task_id = t.id
      w.company_id = t.company_id
      w.customer_id = t.project.customer_id
      w.project_id = t.project_id
      w.started_at = (t.due_at ? t.due_at : (t.milestone ? t.milestone.due_at : tz.now) )
      w.started_at = tz.now if w.started_at.nil? || w.started_at.to_s == ""
      w.duration = t.duration.to_i * 60
      res << w
    end

    return res
  end

end
