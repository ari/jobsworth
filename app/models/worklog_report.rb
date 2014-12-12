# encoding: UTF-8

###
# Worklog Reports are ways of viewing worklogs. They can be used
# as a timesheet, audit, etc
###
class WorklogReport
  PIVOT = 1
  AUDIT = 2
  TIMESHEET = 3
  WORKLOAD = 4

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

  ###
  # The user this report is for
  ###
  attr_reader :current_user

  ###
  # Various variables used for display
  ###
  attr_reader :column_headers
  attr_reader :column_totals
  attr_reader :rows
  attr_reader :row_totals
  attr_reader :total
  attr_reader :generated_report

  ###
  # Creates a report for the given tasks and params
  ###
  def initialize(controller, params)
    tasks = []
    if params[:filter_project].to_i > 0
      tasks = Project.find(params[:filter_project]).tasks
    else
      ids = controller.current_user.projects.collect { |p| p.id }
      tasks = TaskRecord.where("project_id in (?)", ids)
    end

    @tz = controller.tz
    @type = params[:type].to_i
    @current_user = controller.current_user

    @row_value = params[:rows]
    @row_value = @row_value.to_i == 0 ? @row_value : @row_value.to_i
    @column_value = params[:columns]
    @column_value = @column_value.to_i == 0 ? @column_value : @column_value.to_i

    init_start_and_end_dates(params)
    init_work_logs(tasks, params)
    init_rows_and_columns
    init_csv
  end

  ###
  # Calculates and returns the date range of the work logs
  ###
  def range
    return @range if @range

    # Swap to an appropriate range based on entries returned
    start_date = self.start_date
    end_date = self.end_date

    for w in work_logs
      start_date = tz.utc_to_local(w.started_at) if(start_date.nil? || (tz.utc_to_local(w.started_at) < start_date))
      end_date = tz.utc_to_local(w.started_at) if(end_date.nil? || (tz.utc_to_local(w.started_at) > end_date))
    end

    @range = nil
    if start_date && end_date
      days = end_date - start_date
      if days <= 1.days
        @range = 0
      elsif days <= 7.days
        @range = 1
      elsif days <= 31.days
        @range = 3
      else
        @range = 5
      end
    end

    return @range
  end
  
  def make_billing_title(row, column)
    title = I18n.t('billings.pivot')<<" "
    fields = { "1" => I18n.t('billings.tasks'),
               "2" => I18n.t('billings.tags'),
               "3" => I18n.t('billings.users'),
               "4" => I18n.t('billings.clients'),
               "5" => I18n.t('billings.projects'),
               "6" => I18n.t('billings.milestones'),
               "7" => I18n.t('billings.days_of_week'),
               "8" => I18n.t('billings.task_resolution'),
               "9" => I18n.t('billings.date'),
               "20" =>I18n.t('billings.requested_by'),
               I18n.t('properties.type') => I18n.t('properties.type'),
               I18n.t('properties.priority') => I18n.t('properties.priority'),
               I18n.t('properties.severity') => I18n.t('properties.severity') }
    return "" if fields[row].nil? or fields[column].nil?  
    title<<fields[row]
    title<<" "<<I18n.t('billings.by')<<" "
    title<<fields[column]
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
      @start_date = tz.local_to_utc((tz.now-1.month).beginning_of_month)
      @end_date = tz.local_to_utc(tz.now.beginning_of_month)
    when 5
      # This Year
      @start_date = tz.local_to_utc(tz.now.beginning_of_year)
    when 6
      # Last Year
      @start_date = tz.local_to_utc((tz.now-1.year).beginning_of_year)
      @end_date = tz.local_to_utc(tz.now.beginning_of_year)
    when 7
      if params[:start_date] && params[:start_date].length > 1
        begin
          start_date = DateTime.strptime( params[:start_date], current_user.date_format ).to_time
        rescue
          flash['notice'] ||= I18n.t("worklog_reports.errors.invalid_start_date")
          start_date = tz.now
        end

        @start_date = tz.local_to_utc(start_date.midnight)
      end

      if params[:stop_date] && params[:stop_date].length > 1
        begin
          end_date = DateTime.strptime( params[:stop_date], current_user.date_format ).to_time
        rescue
          flash['notice'] ||= I18n.t("worklog_reports.errors.invalid_end_date")
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
  def init_work_logs(tasks, params)
    logs = []

    ids = tasks.collect { |t| t.id }
    logs = WorkLog.level_accessed_by(current_user).where("task_id in (?)", ids).includes(:project, :_user_, :customer, :company => [:custom_attributes], :task => [:tags, :milestone])
    logs = logs.where("started_at >= ?", @start_date) if @start_date
    logs = logs.where("started_at <= ?", @end_date) if @end_date
    logs = logs.where("status <> ?", 1) if (params[:hide_approved].to_i > 0)
    logs = logs.where("status <> ?", 2) if (params[:hide_rejected].to_i > 0)
    logs = logs.where(:user_id =>  params[:filter_user].to_i) if (params[:filter_user].to_i > 0)
    if (params[:worklog_type].to_i > 0)
      if params[:worklog_type].to_i == EventLog::TASK_COMMENT
        logs = logs.comments
      else
        logs = logs.worktimes
      end
    end

    @work_logs = logs.sort_by { |log| log.started_at }
  end

  ###
  # Sets up the column_headers, column_totals, rows, row_totals
  # and total instance vars
  ###
  def init_rows_and_columns
    @total = 0
    @row_totals = { }
    @column_totals = { }
    @column_headers = { }
    @rows = { }

    if start_date
      @column_headers[ '__' ] = "#{I18n.l(start_date, format: current_user.date_format)}"
      @column_headers[ '__' ] << "- #{I18n.l(end_date, format: current_user.date_format)}" if end_date && end_date.yday != start_date.yday
    else
      @column_headers[ '__' ] = "&nbsp;".html_safe
    end

    for w in work_logs
      next if (w.task_id.to_i == 0) || w.duration.to_i == 0
      @total += w.duration

      case @type

      when 1
        # Pivot
        if @column_value == 2
          w.task.tags.each do |tag|
            key = key_from_worklog(tag, @column_value).to_s
            unless @column_headers[ key ]
              @column_headers[ key ] = name_from_worklog( tag, @column_value )
              @column_totals[ key ] ||= 0
            end
            do_column(w, key)
          end
        else
          key = key_from_worklog(w, @column_value).to_s
          unless @column_headers[ key ]
            @column_headers[ key ] = name_from_worklog( w, @column_value )
            if @column_value == 1
              @column_headers[ key ] = w.task.name
            end
            @column_totals[ key ] ||= 0
          end
          do_column(w, key)
        end

      when WorklogReport::TIMESHEET
        # Time sheet
        columns = [ 16, 20, 19]
        w.available_custom_attributes.each do |ca|
          columns << "ca_#{ ca.id }"
        end
        columns << 21

        columns.each do |k|
          key = key_from_worklog(w, k)
          unless @column_headers[ key ]
            @column_headers[ key ] = name_from_worklog( w, k )
            @column_totals[ key ] ||= 0
          end
          do_column(w, key)
        end
      end
    end
  end


  # GENERAL REPORT GENERATION METHODS

  def key_from_worklog(w, r)
    if r == 1
      "#{w.customer.name} #{w.project.name} #{w.task.name} #{w.task.task_num}"
    elsif r == 2
      w.is_a?(Tag) ? w.id : 0
    elsif r == 3
      w.user_id
    elsif r == 4
      w.customer_id
    elsif r == 5
      w.project_id
    elsif r == 6
      w.task.milestone.nil? ? 0 : w.task.milestone.name
    elsif r == 7
      get_days_of_week_key(w)
    elsif r == 8
      w.task.status
    elsif r == 9
      get_date_key(w)
    elsif r == 12
      "comment"
    elsif r == 13
      "#{tz.utc_to_local(w.started_at).strftime("%Y-%m-%d %H:%M")}"
    elsif r == 14
      tz.utc_to_local(w.started_at) + w.duration
    elsif r == 15
      if w.body && !w.body.empty?
        "#{w.customer.name}_#{w.project.name}_#{w.task.name}_#{w.id}"
      else
        "#{w.customer.name}_#{w.project.name}_#{w.task.name}"
      end
    elsif r == 16
      "1_start"
    elsif r == 17
      "2_end"
    elsif r == 18
      "3_task"
    elsif r == 19
      "5_note"
    elsif r == 20
      "4_user"
    elsif r == 21
      "6_approved"
    elsif (property = Property.find_by_filter_name(current_user.company, r))
      w.task.property_value(property)
    elsif r and (match = r.match(/ca_(\d+)/))
      r
    end
  end

  def name_from_worklog(w,r)
    if r == 1
      "#{w.task.issue_num} <a href=\"/tasks/view/#{w.task.task_num}\">#{ERB::Util.h w.task.name}</a> <br /><small>#{ERB::Util.h w.task.full_name}</small>".html_safe
    elsif r == 2
      w.is_a?(Tag) ? "#{w.name}" : I18n.t("worklog_reports.status.none")
    elsif r == 3
      "#{w.user ? w.user.name : I18n.t("work_log.unassigned")}"
    elsif r == 4
      "#{w.customer.name}"
    elsif r == 5
      "#{w.project.full_name}"
    elsif r == 6
      w.task.milestone.nil? ? I18n.t("worklog_reports.status.none") : "#{w.task.milestone.name}"
    elsif r == 7
      get_days_of_week_header(w)
    elsif r == 8
      "#{w.task.status_type}"
    elsif r ==9
      get_date_header(w)
    elsif r == 12
      I18n.t("worklog_reports.status.notes")
    elsif r == 13
      I18n.t("worklog_reports.status.start")
    elsif r == 14
      I18n.t("worklog_reports.status.end")
    elsif r == 15
      "#{I18n.l(tz.utc_to_local(w.started_at), format: "%a " + current_user.date_format )}"
    elsif r == 16
      I18n.t("worklog_reports.status.start")
    elsif r == 17
      I18n.t("worklog_reports.status.end")
    elsif r == 18
      I18n.t("worklog_reports.status.task")
    elsif r == 19
      I18n.t("worklog_reports.status.note")
    elsif r == 20
      I18n.t("worklog_reports.status.user")
    elsif r == 21
      I18n.t("worklog_reports.status.approved")
    elsif (property = Property.find_by_filter_name(current_user.company, r))
      w.task.property_value(property)
    elsif r and (match = r.match(/ca_(\d+)/))
      w.company.custom_attributes.find(match[1]).display_name
    end

  end

  def do_row(rkey, rname, vkey, duration)
    unless @rows[rkey]
      @rows[ rkey ] ||= { }
      @row_totals[rkey] ||= 0
      @rows[ rkey ]['__'] = rname
    end
    if duration.is_a? Fixnum
      @rows[rkey][vkey] ||= 0
      @rows[rkey][vkey] += duration if duration
    else
      @rows[rkey][vkey] ||= ""
      @rows[rkey][vkey] += "<br/>".html_safe if @rows[rkey][vkey].length > 0 && duration
      @rows[rkey][vkey] += "<br/>".html_safe if @rows[rkey][vkey].length > 0 && duration && !(duration.include?('#') || duration.include?('small'))
      @rows[rkey][vkey] += duration if duration
    end
  end


  def do_column(w, key)
    @column_totals[ key ] += w.duration unless ["comment", "1_start", "2_end", "3_task", "4_note"].include?(key)

    rkey = key_from_worklog(w, 15).to_s
    row_name = name_from_worklog(w, 1)

    if @row_value == 2 && !w.task.tags.empty? && (@type == 1)
      w.task.tags.each do |tag|
        rkey = key_from_worklog(tag, @row_value).to_s
        row_name = name_from_worklog(tag, @row_value)
        do_row(rkey, row_name, key, w.duration)
        @row_totals[rkey] += w.duration
      end

    elsif key == "comment"
      body = h(w.body)
      body.gsub!(/\n/, " <br/>".html_safe) if body
      do_row(rkey, row_name, key, body)
      @row_totals[rkey] += w.duration
    elsif key == "1_start"
      do_row(rkey, row_name, key, "<a href=\"/work_logs/edit/#{w.id}\">#{I18n.l(tz.utc_to_local(w.started_at), format: current_user.date_format + " " + current_user.time_format)}</a>".html_safe)
      @row_totals[rkey] += w.duration
    elsif key == "2_end"
      do_row(rkey, row_name, key, "#{I18n.l(tz.utc_to_local(w.started_at) + w.duration, format: current_user.time_format)}")
    elsif key == "3_task"
      do_row(rkey, row_name, key, "#{w.task.issue_num} <a href=\"/tasks/view/#{w.task.task_num}\">#{ERB::Util.h w.task.name}</a> <br/><small>#{ERB::Util.h w.task.full_name}</small>".html_safe)
    elsif key == "4_user"
      do_row(rkey, row_name, key, w.user.name)
    elsif key == "5_note"
      body = h(w.body)
      body.gsub!(/\n/, " <br/>") if body
      do_row(rkey, row_name, key, body)
    elsif key == "6_approved"
      body = w.approved? ? I18n.t("boolean.yes") : I18n.t("boolean.no")
      if current_user.can_approve_work_logs?
        body = "<select onChange='toggleWorkLogApproval(this, #{ w.id })'>"
        body += "<option value='0' #{selected='selected' if w.status.to_i.zero? } >--</option>"
        body += "<option value='1' #{selected='selected' if w.approved? } >#{I18n.t("work_logs.status.approved")}</option>"
        body += "<option value='2' #{selected='selected' if w.rejected? } >#{I18n.t("work_logs.status.rejected")}</option>"
        body += "</select>"
        body = body.html_safe
      end
      do_row(rkey, row_name, key, body)
    elsif (attr = custom_attribute_from_key(key))
      value = w.values_for(attr).join(", ")
      do_row(rkey, row_name, key, value)
    else
      rkey = key_from_worklog(w, @row_value).to_s
      row_name = name_from_worklog(w, @row_value)
      do_row(rkey, row_name, key, w.duration)
      @row_totals[rkey] += w.duration
    end
  end

  def custom_attribute_from_key(str)
    match = str.match(/ca_(\d+)/)
    if match
      return current_user.company.custom_attributes.detect do |ca|
        ca.id == match[1].to_i
      end
    end
  end

  def get_days_of_week_header(w)
    if [0,1,2].include? @range.to_i
      I18n.l(tz.utc_to_local(w.started_at), format: "%a <br/>%d/%m").html_safe
    elsif [3,4].include? @range.to_i
      if tz.utc_to_local(w.started_at).beginning_of_week.month != tz.utc_to_local(w.started_at).beginning_of_week.since(6.days).month
        if tz.utc_to_local(w.started_at).beginning_of_week.month == tz.utc_to_local(w.started_at).month
          ( I18n.t("shared.week") + "#{tz.utc_to_local(w.started_at).strftime("%W").to_i + 1} <br/>" +
            I18n.l(tz.utc_to_local(w.started_at).beginning_of_week, format: "%d/%m") + ' - ' +
            I18n.l(tz.utc_to_local(w.started_at).end_of_month,      format: "%d/%m")
          ).html_safe
        else
          ( I18n.t("shared.week") + "#{tz.utc_to_local(w.started_at).strftime("%W").to_i + 1} <br/>" +
            I18n.l(tz.utc_to_local(w.started_at).beginning_of_month, format: "%d/%m") + ' - ' +
            I18n.l(tz.utc_to_local(w.started_at).beginning_of_week.since(6.days), format: "%d/%m")
          ).html_safe
        end
      else
        ( I18n.t("shared.week") + "#{tz.utc_to_local(w.started_at).strftime("%W").to_i + 1} <br/>" +
          I18n.l(tz.utc_to_local(w.started_at).beginning_of_week, format: "%d/%m") + ' - ' +
          I18n.l(tz.utc_to_local(w.started_at).beginning_of_week.since(6.days), format: "%d/%m")
        ).html_safe
      end
    elsif @range.to_i == 5 || @range.to_i == 6
      I18n.l(tz.utc_to_local(w.started_at), format: "%b <br/>%y").html_safe
    end
  end
  
  def get_date_header(w)
    I18n.l(tz.utc_to_local(w.started_at), format: "%d/%m/%Y").html_safe
  end

  def get_date_key(w)
    "#{tz.utc_to_local(w.started_at).to_date}"    
  end
  
  def get_days_of_week_key(w)
    "#{tz.utc_to_local(w.started_at).to_date.year} #{I18n.l(tz.utc_to_local(w.started_at).to_date, format: '%j')}"
  end

  ###
  # Creates a CSV, saves it and sets up the generated_report instance var
  ###
  def init_csv
    if @column_headers && @column_headers.size > 1
      csv = create_csv
      if !csv.blank?
        @generated_report = GeneratedReport.new
        @generated_report.company = current_user.company
        @generated_report.user = current_user
        @generated_report.filename = "jobsworth_report.csv"
        @generated_report.report = csv
        @generated_report.save
      end
    end
  end

  ###
  # Creates the actual CSV and returns a CSV string
  ###
  def create_csv
    csv_string = ""
    if @column_headers
      CSV.generate(csv_string, :col_sep => "," ) do |csv|

        header = ["Task"]
        @column_headers.sort.each do |key,value|
          next if key == '__'
          header << clean_value(value)
        end
        header << "Total"
        csv << header

        @rows.sort.each do |key, value|
          row = []
          row << clean_value(value["__"])
          @column_headers.sort.each do |k,v|
            next if k == '__'
            val = nil
            val = value[k] if value[k] && value[k].is_a?(Fixnum)
            if v == "Approved" && value[k] !~ /^No|Yes$/
              val = $1 if value[k] =~ /<option[^<>]*selected[^<>]*>([^<>]*)<\/option>/
            else
              val = clean_value(value[k]) if val.nil? && value[k]
            end
            row << val
          end
          row << @row_totals[key]
          csv << row
        end

        row = []
        row << 'Total'
        @column_headers.sort.each do |key,value|
          next if key == '__'
          val = nil
          val = @column_totals[key] if @column_totals[key] > 0
          row << val
        end
        row << @total
        csv << row
      end
    end
    csv_string
  end

  ###
  # Cleans up a CSV value
  ###
  def clean_value(value)
    res = value
    begin
      res = value.gsub(/<[a-zA-Z\/][^>]*>/,'')
    rescue
    end

    return res
  end

  # Returns the controller's flash hash
  def flash
    @controller.send(:flash)
  end

end
