class WidgetsController < ApplicationController

  def show
    begin
      @widget = Widget.find(params[:id], :conditions => ["company_id = ? AND user_id = ?", current_user.company_id, current_user.id])
    rescue
      render :nothing => true
      return
    end

    case @widget.widget_type
    when 0
      # Tasks
      order = case @widget.order_by
              when 'priority':
                  "tasks.severity_id + tasks.priority desc, CASE WHEN (tasks.due_at IS NULL AND milestones.due_at IS NULL) THEN 1 ELSE 0 END, CASE WHEN (tasks.due_at IS NULL AND tasks.milestone_id IS NOT NULL) THEN milestones.due_at ELSE tasks.due_at END"
              when 'date':
                  "tasks.created_at desc"
              end
      @items = Task.find(:all, :conditions => ["tasks.project_id IN (#{current_project_ids}) AND tasks.completed_at IS NULL AND tasks.company_id = #{current_user.company_id} AND (tasks.hide_until IS NULL OR tasks.hide_until < '#{tz.now.utc.to_s(:db)}') AND (tasks.milestone_id NOT IN (#{completed_milestone_ids}) OR tasks.milestone_id IS NULL)"],  :order => order, :include => [:tags, :work_logs, :milestone, { :project => :customer }, :dependencies, :dependants, :users, :work_logs, :todos], :limit => @widget.number  )
    when 1
      # Project List
      @projects = current_user.projects.find(:all, :order => 't1_r2, projects.name', :conditions => ["projects.completed_at IS NULL"], :include => [ :customer, :milestones])
      @completed_projects = current_user.completed_projects.size
    when 2
      # Activities
      @activities = EventLog.find(:all, :order => "event_logs.created_at DESC", :limit => @widget.number, :conditions => ["company_id = ? AND (event_logs.project_id IN ( #{current_project_ids} ) OR event_logs.project_id IS NULL)", current_user.company_id] )
    when 3
        # Chat
    when 4
        # Active Tasks
    when 5
        # Schedule
    end

    render :update do |page|
      case @widget.widget_type
      when 0
        page.replace_html @widget.dom_id, :partial => 'tasks/task_list', :locals => { :tasks => @items }
      when 1
        page.replace_html @widget.dom_id, :partial => 'activities/project_overview'
      when 2
        page.replace_html @widget.dom_id, :partial => 'activities/recent_work'
      end

      page.call("updateTooltips")
      
    end

  end

  def edit
  end

  def list
  end
  
  def toggle_display
    begin
      @widget = current_user.widgets.find(params[:id])
    rescue
      render :nothing => true, :layout => false
      return
    end 
    
    @widget.collapsed = !@widget.collapsed?
    
    render :update do |page|
      if @widget.collapsed?
        page.hide @widget.dom_id
        page["header-#{@widget.dom_id}"].className = "widget-collapsed"
      else 
        page.show @widget.dom_id
        page["header-#{@widget.dom_id}"].className = "widget-open"
      end
    end
    
    @widget.save
    
  end
end
