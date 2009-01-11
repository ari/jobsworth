# Massage the WorkLogs in different ways, saving reports for later access
# as well as CSV downloading.
#
class ReportsController < ApplicationController

  require_dependency 'fastercsv'

  def get_date_header(w)
    if [0,1,2].include? @range.to_i
      tz.utc_to_local(w.started_at).strftime_localized("%a <br/>%d/%m")
    elsif [3,4].include? @range.to_i
      if tz.utc_to_local(w.started_at).beginning_of_week.month != tz.utc_to_local(w.started_at).beginning_of_week.since(6.days).month
        if tz.utc_to_local(w.started_at).beginning_of_week.month == tz.utc_to_local(w.started_at).month
          "#{_('Week')} #{tz.utc_to_local(w.started_at).strftime_localized("%W").to_i + 1} <br/>" +  tz.utc_to_local(w.started_at).beginning_of_week.strftime_localized("%d/%m") + ' - ' + tz.utc_to_local(w.started_at).end_of_month.strftime_localized("%d/%m")
        else
          "#{_('Week')} #{tz.utc_to_local(w.started_at).strftime_localized("%W").to_i + 1} <br/>" +  tz.utc_to_local(w.started_at).beginning_of_month.strftime_localized("%d/%m") + ' - ' + tz.utc_to_local(w.started_at).beginning_of_week.since(6.days).strftime_localized("%d/%m")
        end
      else
        "#{_('Week')} #{tz.utc_to_local(w.started_at).strftime_localized("%W").to_i + 1} <br/>" +  tz.utc_to_local(w.started_at).beginning_of_week.strftime_localized("%d/%m") + ' - ' + tz.utc_to_local(w.started_at).beginning_of_week.since(6.days).strftime_localized("%d/%m")
      end
    elsif @range.to_i == 5 || @range.to_i == 6
      tz.utc_to_local(w.started_at).strftime_localized("%b <br/>%y")
    end
  end

  def get_date_key(w)
    if [0,1,2].include? @range.to_i
      "#{tz.utc_to_local(w.started_at).to_date.year} #{tz.utc_to_local(w.started_at).to_date.strftime_localized('%u')}"
    elsif [3,4].include? @range.to_i
      "#{tz.utc_to_local(w.started_at).to_date.year} #{tz.utc_to_local(w.started_at).to_date.strftime_localized('%V')}"
    elsif @range.to_i == 5 || @range.to_i == 6
      "#{tz.utc_to_local(w.started_at).to_date.year} #{tz.utc_to_local(w.started_at).to_date.strftime_localized('%m')}"
    end
  end

  def key_from_worklog(w, r)
    case r
    when 1
      "#{w.customer.name} #{w.project.name} #{w.task.name} #{w.task.task_num}"
    when 2
      w.is_a?(Tag) ? w.id : 0
    when 3
      w.user_id
    when 4
      w.customer_id
    when 5
      w.project_id
    when 6
      w.task.milestone.nil? ? 0 : w.task.milestone.name
    when 7
      get_date_key(w)
    when 8
      w.task.status
    when 9
      w.task.type_id
    when 10
      w.task.severity_id + 2
    when 11
      w.task.priority + 2
    when 12
      "comment"
    when 13
      "#{tz.utc_to_local(w.started_at).strftime("%Y-%m-%d %H:%M")}"
    when 14
      tz.utc_to_local(w.started_at) + w.duration
    when 15
      if w.body && !w.body.empty?
        "#{w.customer.name}_#{w.project.name}_#{w.task.name}_#{w.id}"
      else
        "#{w.customer.name}_#{w.project.name}_#{w.task.name}"
      end
    when 16
      "1_start"
    when 17
      "2_end"
    when 18
      "3_task"
    when 19
      "5_note"
    when 20
      "#{w.task.requested_by}"
    when 21
      "4_user"
    end
    
  end

  def name_from_worklog(w,r)
    case r
    when 1
      "#{w.task.issue_num} <a href=\"/tasks/view/#{w.task.task_num}\">#{w.task.name}</a> <br /><small>#{w.task.full_name}</small>"
    when 2
      w.is_a?(Tag) ? "#{w.name}" : "none"
    when 3
      "#{w.user ? w.user.name : _("Unassigned")}"
    when 4
      "#{w.customer.name}"
    when 5
      "#{w.project.full_name}"
    when 6
      w.task.milestone.nil? ? "none" : "#{w.task.milestone.name}"
    when 7
      get_date_header(w)
    when 8
      "#{w.task.status_type}"
    when 9
      "#{w.task.issue_type}"
    when 10
      "#{w.task.severity_type}"
    when 11
      "#{w.task.priority_type}"
    when 12
      _("Notes")
    when 13
      _("Start")
    when 14
      _("End")
    when 15
      "#{tz.utc_to_local(w.started_at).strftime_localized( "%a " + current_user.date_format )}"
    when 16
      _("Start")
    when 17
      _("End")
    when 18
      _("Task")
    when 19
      _("Note")
    when 20 
      "#{w.task.requested_by}"
    when 21
      _("User")
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
      @rows[rkey][vkey] += "<br/>" if @rows[rkey][vkey].length > 0 && duration
      @rows[rkey][vkey] += "<br/>" if @rows[rkey][vkey].length > 0 && duration && !(duration.include?('#') || duration.include?('small'))
      @rows[rkey][vkey] += duration if duration
    end 
  end


  def do_column(w, key)
    logger.debug("#{ key } - #{w.task_id} ##{w.task.task_num} || #{w.duration.to_i}")

    @column_totals[ key ] += w.duration unless ["comment", "1_start", "2_end", "3_task", "4_note"].include?(key)

    if @row_value == 2 && !w.task.tags.empty? && (@type == 1 || @type == 4)
      w.task.tags.each do |tag|
        rkey = key_from_worklog(tag, @row_value).to_s
        row_name = name_from_worklog(tag, @row_value)
        do_row(rkey, row_name, key, w.duration)
        @row_totals[rkey] += w.duration
      end

    elsif key == "comment"
      rkey = key_from_worklog(w, 15).to_s
      row_name = name_from_worklog(w, 1)
      body = w.body
      body.gsub!(/\n/, " <br/>") if body
      do_row(rkey, row_name, key, body)
      @row_totals[rkey] += w.duration
    elsif key == "1_start"
      rkey = key_from_worklog(w, 13).to_s
      row_name = name_from_worklog(w, 15)
      do_row(rkey, row_name, key, "<a href=\"/tasks/edit_log/#{w.id}\">#{tz.utc_to_local(w.started_at).strftime_localized(current_user.time_format)}</a>")
      @row_totals[rkey] += w.duration
    elsif key == "2_end"
      rkey = key_from_worklog(w, 13).to_s
      row_name = name_from_worklog(w, 15)
      do_row(rkey, row_name, key, "#{(tz.utc_to_local(w.started_at) + w.duration).strftime_localized(current_user.time_format)}")
    elsif key == "3_task"
      rkey = key_from_worklog(w, 13).to_s
      row_name = name_from_worklog(w, 15)
      do_row(rkey, row_name, key, "#{w.task.issue_num} <a href=\"/tasks/view/#{w.task.task_num}\">#{w.task.name}</a> <br/><small>#{w.task.full_name}</small>")
    elsif key == "4_user"
      rkey = key_from_worklog(w, 13).to_s
      row_name = name_from_worklog(w, 15)
      do_row(rkey, row_name, key, w.user.name)
    elsif key == "5_note"
      rkey = key_from_worklog(w, 13).to_s
      row_name = name_from_worklog(w, 15)
      body = w.body
      body.gsub!(/\n/, " <br/>") if body
      do_row(rkey, row_name, key, body)
    else
      rkey = key_from_worklog(w, @row_value).to_s
      row_name = name_from_worklog(w, @row_value)
      do_row(rkey, row_name, key, w.duration)
      @row_totals[rkey] += w.duration
    end
  end


  def list
    sql_filter = ""
    date_filter = ""
    filename = "clockingit"

    @tags = Tag.top_counts({ :company_id => current_user.company_id, :project_ids => current_project_ids})
    @users = User.find(:all, :order => 'name', :conditions => ['users.company_id = ?', current_user.company_id], :joins => "INNER JOIN project_permissions ON project_permissions.user_id = users.id")
    
    if filter = params[:report]
      @type = filter[:type].to_i
      @range = filter[:range]

      @row_value = filter[:rows].to_i
      @column_value = filter[:columns].to_i

      customer_id = filter[:client_id]
      user_id = filter[:user_id]
      project_id = filter[:project_id]

      task_status = filter[:status].to_i
      task_type_id = filter[:type_id].to_i
      task_priority = filter[:priority].to_i
      task_severity = filter[:severity_id].to_i
      task_tags = filter[:tags]

      filename << "_" + ["pivot", "audit", "time_sheet", "workload"][@type-1]

      if @type != 4
        # Pivot, Timesheet, Audit
        if customer_id.to_i > 0
          sql_filter = sql_filter + " AND work_logs.customer_id = #{customer_id}"
          filename << "_" + Customer.find(customer_id).name.gsub(/ /, "-").downcase
        end

        if project_id.to_i > 0
          sql_filter = sql_filter + " AND work_logs.project_id = #{project_id}"
          filename << "_" + Project.find(project_id).name.gsub(/ /, "-").downcase
        end

        if user_id.to_i > 0
          sql_filter = sql_filter + " AND work_logs.user_id = #{user_id}"
          filename << "_" + User.find(user_id).name.gsub(/ /, "-").downcase
        end

        case @range.to_i
        when 0
          # Today
          date_filter = " AND work_logs.started_at >= '#{tz.local_to_utc(tz.now.at_midnight).to_s(:db)}'"
          filename << "_" + tz.now.at_midnight.strftime("%Y%m%d") + "-" + tz.now.strftime("%Y%m%d")
        when 8
          # Yesterday
          date_filter = " AND work_logs.started_at >= '#{tz.local_to_utc((tz.now - 1.day).at_midnight).to_s(:db)}' AND work_logs.started_at < '#{tz.local_to_utc(tz.now.at_midnight).to_s(:db)}'"
          filename << "_" + (tz.now - 1.day).at_midnight.strftime("%Y%m%d") + "-" + tz.now.at_midnight.strftime("%Y%m%d")
        when 1
          # This Week
          date_filter = " AND work_logs.started_at >= '#{tz.local_to_utc(tz.now.beginning_of_week).to_s(:db)}'"
          filename << "_" + tz.now.beginning_of_week.strftime("%Y%m%d")  + "-" + tz.now.strftime("%Y%m%d")
        when 2
          # Last Week
          date_filter = " AND work_logs.started_at >= '#{tz.local_to_utc((tz.now - 1.week).beginning_of_week).to_s(:db)}' AND work_logs.started_at < '#{tz.local_to_utc(tz.now.beginning_of_week).to_s(:db)}'"
          filename << "_" + 1.week.ago.beginning_of_week.strftime("%Y%m%d")
          filename << "-" + tz.now.beginning_of_week.strftime("%Y%m%d")
        when 3
          # This Month
          date_filter = " AND work_logs.started_at >= '#{tz.local_to_utc(tz.now.beginning_of_month).to_s(:db)}' AND work_logs.started_at < '#{tz.local_to_utc(tz.now.next_month.beginning_of_month).to_s(:db)}'"
          filename << "-" + tz.now.beginning_of_month.strftime("%Y%m%d")  + "-" + tz.now.strftime("%Y%m%d")
        when 4
          # Last Month
          date_filter = " AND work_logs.started_at >= '#{tz.local_to_utc(tz.now.last_month.beginning_of_month).to_s(:db)}'  AND work_logs.started_at < '#{tz.local_to_utc(tz.now.beginning_of_month).to_s(:db)}'"
          filename << "_" + tz.now.last_month.beginning_of_month.strftime("%Y%m%d")
          filename << "-" + tz.now.beginning_of_month.strftime("%Y%m%d")
        when 5
          # This Year
          date_filter = " AND work_logs.started_at >= '#{tz.local_to_utc(tz.now.beginning_of_year).to_s(:db)}'"
          filename << "-" + tz.now.beginning_of_year.strftime("%Y%m%d")  + "-" + tz.now.strftime("%Y%m%d")
        when 6
          # Last Year
          date_filter = " AND work_logs.started_at >= '#{tz.local_to_utc(tz.now.last_year.beginning_of_year).to_s(:db)}'  AND work_logs.started_at < '#{tz.local_to_utc(tz.now.beginning_of_year).to_s(:db)}'"
          filename << "_" + tz.now.last_year.beginning_of_year.strftime("%Y%m%d")
          filename << "-" + tz.now.beginning_of_year.strftime("%Y%m%d")
        when 7
          if filter[:stop_date] && filter[:start_date].length > 1
            start_date = DateTime.strptime( filter[:start_date], current_user.date_format ).to_time rescue begin
                                                                                                             flash['notice'] ||= _("Invalid start date")
                                                                                                             start_date = tz.now
                                                                                                           end 
            date_filter = date_filter + " AND work_logs.started_at >= '#{tz.local_to_utc(start_date.midnight).to_s(:db)}'"
          end

          if filter[:stop_date] && filter[:stop_date].length > 1
            end_date = DateTime.strptime( filter[:stop_date], current_user.date_format ).to_time rescue begin
                                                                                                          flash['notice'] ||= _("Invalid end date")
                                                                                                          end_date = tz.now
                                                                                                        end 
            date_filter = date_filter + " AND work_logs.started_at < '#{tz.local_to_utc( (end_date + 1.day).midnight).to_s(:db)}'"
          end

          filename << "_" + start_date.strftime("%Y%m%d") if start_date
          filename << "_" + end_date.strftime("%Y%m%d") if end_date

        end

        join = ""
        if task_status > -1 || task_type_id > -1 || task_priority > -3 || task_severity > -3
          join << " AND tasks.status = #{task_status}" if task_status > -1
          join << " AND tasks.type_id = #{task_type_id}" if task_type_id > -1
          join << " AND tasks.priority = #{task_priority}" if task_priority > -3
          join << " AND tasks.severity_id = #{task_severity}" if task_severity > -3
        end

        unless task_tags.nil? || task_tags.empty?
          task_ids = Task.tagged_with(task_tags.downcase, { :company_id => current_user.company_id, :filter_status => "-1" } ).collect { |t| t.id }.join(",")
          task_ids = "0" if task_ids.empty?
          sql_filter << " AND work_logs.task_id IN (#{task_ids})"
        end

        @projects = []
        @projects = current_user.projects.find(:all, :order => 'name') unless project_id.to_i == -2
        @projects += current_user.completed_projects.find(:all, :order => 'name') if(project_id.to_i < 0 || project_id.to_i > 0)
        @logs = []
        @projects.each do |p|
          if join != ""
            @logs += p.work_logs.find(:all, :select => "work_logs.*", :order => "work_logs.project_id", :joins => "LEFT JOIN tasks ON tasks.id = work_logs.task_id", :conditions => ["work_logs.company_id = ? AND work_logs.duration > 0" + sql_filter + date_filter + join, current_user.company.id])
          else
            @logs += p.work_logs.find(:all, :order => "work_logs.project_id", :conditions => ["work_logs.company_id = ? AND duration > 0" + sql_filter + date_filter, current_user.company.id])
          end
        end

      else
        # Workload report

        if customer_id.to_i > 0
          sql_filter = sql_filter + " AND tasks.project_id IN (#{Project.find(:all, :conditions => ["customer_id = ?", customer_id]).collect{|p| p.id}.join(',') || '0' })"
          filename << "_" + Customer.find(customer_id).name.gsub(/ /, "-").downcase
        end

        if project_id.to_i > 0
          sql_filter = sql_filter + " AND tasks.project_id = #{project_id}"
          filename << "_" + Project.find(project_id).name.gsub(/ /, "-").downcase
        end

        if user_id.to_i > 0
          task_ids = User.find(user_id.to_i).tasks.collect { |t| t.id }.join(',')
          if task_ids == ''
            sql_filter << " AND tasks.id IN (0) "
          else
            sql_filter << " AND tasks.id IN (#{task_ids}) "
          end
          filename << "_" + User.find(user_id).name.gsub(/ /, "-").downcase
        end

        join = ""
        if task_status > -1 || task_type_id > -1 || task_priority > -3 || task_severity > -3
          join << " AND tasks.status = #{task_status}" if task_status > -1
          join << " AND tasks.type_id = #{task_type_id}" if task_type_id > -1
          join << " AND tasks.priority = #{task_priority}" if task_priority > -3
          join << " AND tasks.severity_id = #{task_severity}" if task_severity > -3
        end

        unless task_tags.nil? || task_tags.empty?
          task_ids = Task.tagged_with(task_tags.downcase, { :company_id => current_user.company_id, :filter_status => "-1" } ).collect { |t| t.id }.join(",")
          task_ids = "0" if task_ids.empty?
          sql_filter << " AND tasks.id IN (#{task_ids})"
        end

        @projects = current_user.projects
        @projects += current_user.completed_projects if( project_id.to_i == -1 || project_id.to_i > 0 )
        @tasks = []
        @projects.each do |p|
          @tasks += p.tasks.find(:all, :order => "tasks.project_id", :conditions => ["tasks.company_id = ? AND tasks.completed_at IS NULL AND tasks.status < 2 " + sql_filter + date_filter + join, current_user.company_id], :include => [:project, :users, :milestone, :company, :tags])
        end

        @logs = []
        @tasks.each do |t|
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
              @logs << w
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
            @logs << w
          end

        end
      end

      # Swap to an appropriate range based on entries returned
      for w in @logs
        logger.info( "#{w.started_at} -> #{tz.utc_to_local(w.started_at)} < #{start_date}")
        start_date = tz.utc_to_local(w.started_at) if(start_date.nil? || (tz.utc_to_local(w.started_at) < start_date))
        end_date = tz.utc_to_local(w.started_at) if(end_date.nil? || (tz.utc_to_local(w.started_at) > end_date))
      end

      if start_date && end_date
        @days = end_date - start_date
        if @days <= 1.days
          @range = 0
        elsif @days <= 7.days
          @range = 1
        elsif @days <= 31.days
          @range = 3
        else
          @range = 5
        end
      end

      @total = 0
      @row_totals = { }
      @column_totals = { }
      @column_headers = { }
      @rows = { }

      if start_date
        @column_headers[ '__' ] = "#{start_date.strftime_localized(current_user.date_format)}"
        @column_headers[ '__' ] << "- #{end_date.strftime_localized(current_user.date_format)}" if end_date && end_date.yday != start_date.yday
      else
        @column_headers[ '__' ] = "&nbsp;"
      end

      for w in @logs

        next if (w.task_id.to_i == 0) || w.duration.to_i == 0
        @total += w.duration

        case @type

        when 1, 4
          # Pivot
          if @column_value == 2 && !w.task.tags.empty?
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

        when 2
          # Audit
          [12].each do |k|
            key = key_from_worklog(w,k).to_s
            unless @column_headers[ key ]
              @column_headers[ key ] = name_from_worklog( w, k )
              @column_totals[ key ] ||= 0
            end
            do_column(w, key)
          end 
        when 3
          # Time sheet
          [16, 17, 18, 21, 19].each do |k|
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

    csv = create_csv if @column_headers && @column_headers.size > 1
    unless csv.nil? || csv.empty?
      @generated_report = GeneratedReport.new
      @generated_report.company = current_user.company
      @generated_report.user = current_user
      @generated_report.filename = filename + ".csv"
      @generated_report.report = csv
      @generated_report.save
    else
      flash['notice'] = _("Empty report, log more work!") if params[:report]
    end

  end

  def create_csv
    csv_string = ""
    if @column_headers
      csv_string = FasterCSV.generate( :col_sep => "," ) do |csv|

        header = [nil]
        @column_headers.sort.each do |key,value|
          next if key == '__'
          header << [value.gsub(/<[a-zA-Z\/][^>]*>/,'')]
        end
        header << [_("Total")]
        csv << header

        @rows.sort.each do |key, value|
          row = []
          row << [value['__'].gsub(/<[a-zA-Z\/][^>]*>/,'')]
          @column_headers.sort.each do |k,v|
            next if k == '__'
            val = nil
            val = value[k]/60 if value[k] && value[k].is_a?(Fixnum)
            val = value[k].gsub(/<[a-zA-Z\/][^>]*>/,'') if val.nil? && value[k]
            row << [val]
          end
          row << [@row_totals[key]/60]
          csv << row
        end

        row = []
        row << [_('Total')]
        @column_headers.sort.each do |key,value|
          next if key == '__'
          val = nil
          val = @column_totals[key]/60 if @column_totals[key] > 0
          row << [val]
        end
        row << [@total/60]
        csv << row


      end
    end
    csv_string
  end

  def get_csv
    @report = GeneratedReport.find(params[:id], :conditions => ["user_id = ? AND company_id = ?", current_user.id, current_user.company_id])
    if @report
      send_data(@report.report,
                :type => 'text/csv; charset=utf-8; header=present',
                :filename => @report.filename)
    else
      redirect_to :action => 'list'
    end

  end

  def get_projects
    if params[:client_id].to_i == 0
      @projects = (current_user.projects.find(:all, :order => 'name').collect {|p| "{\"text\":\"#{(p.name + " / " + p.customer.name).gsub(/"/,'\"')}\", \"value\":\"#{p.id.to_s}\"}" } +
        current_user.completed_projects.find(:all, :order => 'name').collect {|p| "{\"text\":\"#{(p.name + " / " + p.customer.name + " - " + _('Completed')).gsub(/"/,'\"')}\", \"value\":\"#{p.id.to_s}\"}" }).join(',')
    else
      @projects = (current_user.projects.find(:all, :order => 'name' , :conditions => ["projects.customer_id = ?", params[:client_id] ]).collect {|p| "{\"text\":\"#{p.name.gsub(/"/,'\"')}\", \"value\":\"#{p.id.to_s}\"}" } +
                   current_user.completed_projects.find(:all, :order => 'name' , :conditions => ["projects.customer_id = ?", params[:client_id] ]).collect {|p| "{\"text\":\"#{(p.name + " - " + _('Completed')).gsub(/"/,'\"')}\", \"value\":\"#{p.id.to_s}\"}" }
                   ).join(',')
    end

    res = '{"options":[{"value":"0", "text":"' + _('[Active Projects]') + '"},{"value":"-1", "text":"' + _('[Any Project]') + '"},{"value":"-2", "text":"' + _('[Closed Projects]') + '"}'

    res << ", #{@projects}" unless @projects.nil? || @projects.empty?
    res << ']}'
    render :text => res
  end


end
