# Filter WorkLogs in different ways, with pagination
class TimelineController < ApplicationController

  def list

    filter = ""
    if params[:filter_project].to_i > 0
      filter << " AND work_logs.project_id = #{params[:filter_project]}"
    else
      filter << " AND work_logs.project_id IN (#{current_project_ids})"
    end
    filter << " AND work_logs.user_id = #{params[:filter_user]}" if params[:filter_user].to_i > 0
    filter << " AND work_logs.log_type = #{WorkLog::TASK_CREATED}" if params[:filter_status].to_i == WorkLog::TASK_CREATED
    filter << " AND work_logs.log_type IN (#{WorkLog::TASK_CREATED},#{WorkLog::TASK_REVERTED},#{WorkLog::TASK_COMPLETED})" if params[:filter_status].to_i == WorkLog::TASK_REVERTED
    filter << " AND work_logs.log_type = #{WorkLog::TASK_COMPLETED}" if params[:filter_status].to_i == WorkLog::TASK_COMPLETED
    filter << " AND work_logs.log_type = #{WorkLog::TASK_COMMENT}" if params[:filter_status].to_i == WorkLog::TASK_COMMENT
    filter << " AND work_logs.log_type = #{WorkLog::TASK_MODIFIED}" if params[:filter_status].to_i == WorkLog::TASK_MODIFIED
    filter << " AND work_logs.duration > 0" if params[:filter_status].to_i == WorkLog::TASK_WORK_ADDED

   case params[:filter_date].to_i
        when 1
          # This Week
          filter << " AND work_logs.started_at > '#{tz.utc_to_local(Time.now.beginning_of_week).strftime("%Y-%m-%d %H:%M:%S")}'"
        when 2
          # Last Week
          filter << " AND work_logs.started_at > '#{tz.utc_to_local(1.week.ago.beginning_of_week).strftime("%Y-%m-%d %H:%M:%S")}' AND work_logs.started_at < '#{tz.utc_to_local(Time.now.beginning_of_week).strftime("%Y-%m-%d %H:%M:%S")}'"
        when 3
          # This Month
          filter << " AND work_logs.started_at > '#{tz.utc_to_local(Time.now.beginning_of_month).strftime("%Y-%m-%d %H:%M:%S")}'"
        when 4
          # Last Month
          filter << " AND work_logs.started_at > '#{tz.utc_to_local(Time.now.last_month.beginning_of_month).strftime("%Y-%m-%d %H:%M:%S")}'  AND work_logs.started_at < '#{tz.utc_to_local(Time.now.beginning_of_month).strftime("%Y-%m-%d %H:%M:%S")}'"
        when 5
          # This Year
          filter << " AND work_logs.started_at > '#{tz.utc_to_local(Time.now.beginning_of_year).strftime("%Y-%m-%d %H:%M:%S")}'"
        when 6
          # Last Year
          filter << " AND work_logs.started_at > '#{tz.utc_to_local(Time.now.last_year.beginning_of_year).strftime("%Y-%m-%d %H:%M:%S")}'  AND work_logs.started_at < '#{tz.utc_to_local(Time.now.beginning_of_year).strftime("%Y-%m-%d %H:%M:%S")}'"
        when 7
          if filter[:stop_date] && filter[:start_date].length > 1
            start_date = DateTime.strptime( filter[:start_date], current_user.date_format ).to_time
            filter << " AND work_logs.started_at > '#{tz.utc_to_local(start_date).strftime("%Y-%m-%d 00:00:00")}'"
          end

          if filter[:stop_date] && filter[:stop_date].length > 1
            end_date = DateTime.strptime( filter[:stop_date], current_user.date_format ).to_time
            filter << " AND work_logs.started_at < '#{tz.utc_to_local(end_date).strftime("%Y-%m-%d 23:59:59")}'"
          end

      end

#    @offset = params[:page].to_i * 100

    @logs = WorkLog.paginate(:all, :order => "work_logs.started_at desc,work_logs.id desc", :conditions => ["work_logs.company_id = ? #{filter} AND work_logs.project_id IN (#{current_project_ids})", current_user.company_id], :include => [:user, {:task => [ :tags ]}, :project, ], :per_page => 100, :page => params[:page] )

#    @count = WorkLog.count(:conditions => ["work_logs.company_id=? AND work_logs.project_id IN (#{current_project_ids}) #{filter}", current_user.company_id])
  end

end
