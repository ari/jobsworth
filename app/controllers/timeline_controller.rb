# Filter WorkLogs in different ways, with pagination
class TimelineController < ApplicationController
  
  def list

    filter = ""
    work_log = false
    @filter_params = {}

    [:filter_user, :filter_status, :filter_project, :filter_date].each do |fp|
      @filter_params[fp] = params[fp] unless params[fp].blank?
    end

    if( [EventLog::FORUM_NEW_POST, EventLog::WIKI_CREATED, EventLog::WIKI_MODIFIED].include? params[:filter_status].to_i || params[:filter_status].nil? )
      filter << " AND event_logs.user_id = #{params[:filter_user]}" if params[:filter_user].to_i > 0
      filter << " AND event_logs.event_type = #{EventLog::FORUM_NEW_POST}" if params[:filter_status].to_i == EventLog::FORUM_NEW_POST
      filter << " AND event_logs.event_type = #{EventLog::WIKI_CREATED}" if params[:filter_status].to_i == EventLog::WIKI_CREATED
      filter << " AND event_logs.event_type IN (#{EventLog::WIKI_CREATED},#{EventLog::WIKI_MODIFIED})" if params[:filter_status].to_i == EventLog::WIKI_MODIFIED
    else
      filter << " AND work_logs.user_id = #{params[:filter_user]}" if params[:filter_user].to_i > 0
      filter << " AND work_logs.log_type = #{EventLog::TASK_CREATED}" if params[:filter_status].to_i == EventLog::TASK_CREATED
      filter << " AND work_logs.log_type IN (#{EventLog::TASK_CREATED},#{EventLog::TASK_REVERTED},#{EventLog::TASK_COMPLETED})" if params[:filter_status].to_i == EventLog::TASK_REVERTED
      filter << " AND work_logs.log_type = #{EventLog::TASK_COMPLETED}" if params[:filter_status].to_i == EventLog::TASK_COMPLETED
      filter << " AND (work_logs.log_type = #{EventLog::TASK_COMMENT} OR work_logs.comment = 1)" if params[:filter_status].to_i == EventLog::TASK_COMMENT
      filter << " AND work_logs.log_type = #{EventLog::TASK_MODIFIED}" if params[:filter_status].to_i == EventLog::TASK_MODIFIED
      filter << " AND work_logs.duration > 0" if params[:filter_status].to_i == EventLog::TASK_WORK_ADDED
    end 

    if filter.length > 0
      work_log = true
    end


    case params[:filter_date].to_i
    when 1
      # This Week
      filter << " AND work_logs.started_at > '#{tz.utc_to_local(Time.now.beginning_of_week.utc).to_s(:db)}'"
    when 2
      # Last Week
      filter << " AND work_logs.started_at > '#{tz.utc_to_local(1.week.ago.beginning_of_week.utc).to_s(:db)}' AND work_logs.started_at < '#{tz.utc_to_local(Time.now.beginning_of_week.utc).to_s(:db)}'"
    when 3
      # This Month
      filter << " AND work_logs.started_at > '#{tz.utc_to_local(Time.now.beginning_of_month.utc).to_s(:db)}'"
    when 4
      # Last Month
      filter << " AND work_logs.started_at > '#{tz.utc_to_local(Time.now.last_month.beginning_of_month.utc).to_s(:db)}'  AND work_logs.started_at < '#{tz.utc_to_local(Time.now.beginning_of_month.utc).to_s(:db)}'"
    when 5
      # This Year
      filter << " AND work_logs.started_at > '#{tz.utc_to_local(Time.now.beginning_of_year.utc).to_s(:db)}'"
    when 6
      # Last Year
      filter << " AND work_logs.started_at > '#{tz.utc_to_local(Time.now.last_year.beginning_of_year.utc).to_s(:db)}'  AND work_logs.started_at < '#{tz.utc_to_local(Time.now.beginning_of_year.utc).to_s(:db)}'"
    end

    if params[:filter_project].to_i > 0
      filter = " AND work_logs.project_id = #{params[:filter_project]}" + filter
    else
      filter = " AND (work_logs.project_id IN (#{current_project_ids}) OR work_logs.project_id IS NULL)" + filter
    end
    
    if( ([EventLog::FORUM_NEW_POST, EventLog::WIKI_CREATED, EventLog::WIKI_MODIFIED].include? params[:filter_status].to_i) || work_log == false)
      filter.gsub!(/work_logs/, 'event_logs')
      filter.gsub!(/started_at/, 'created_at')
      
      @logs = EventLog.paginate(:all, :include => [:user], :order => "event_logs.created_at desc", :conditions => ["event_logs.company_id = ? #{filter}", current_user.company_id], :per_page => 100, :page => params[:page] )
      
      worklog_ids = []
      @logs.each do |l|
        if l.target_type == 'WorkLog'
          worklog_ids << l.target_id
        end
      end
      
      @worklogs = { }
      WorkLog.find(worklog_ids, :include => [:user, {:task => [ :milestone, :tags, :dependencies, :dependants, :users, { :project => [:customer] } ]}  ]).each do |w|
        @worklogs[w.id] = w
      end
      
    else 
      @logs = WorkLog.paginate(:all, :order => "work_logs.started_at desc,work_logs.id desc", :conditions => ["work_logs.company_id = ? #{filter} AND work_logs.project_id IN (#{current_project_ids})", current_user.company_id], :include => [:user, {:task => [ :milestone, :tags, :dependencies, :dependants, :users, { :project => [:customer] } ]}], :per_page => 100, :page => params[:page] )
    end 
  end

end
