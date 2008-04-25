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
      # Tasks / Day
      case @widget.number
      when 7
        start = tz.local_to_utc(6.days.ago.midnight)
        step = 1
        interval = 1.day / step
        range = 7
        tick = "%a"
      when 30 
        start = tz.local_to_utc(tz.now.beginning_of_week.midnight - 5.weeks)
        step = 2
        interval = 1.week / step
        range = 6
        tick = _("Week") + " %W"
      when 180
        start = tz.local_to_utc(tz.now.beginning_of_month.midnight - 5.months)
        step = 4
        interval = 1.month / step
        range = 6
        tick = "%b"
      end

      @items = []
      @dates = []
      @range = []
      0.upto(range * step) do |d|
          
        if @widget.filter_by != 'me'
          @items[d] = current_user.company.tasks.count(:conditions => ["project_id IN (#{current_project_ids}) AND created_at < ? AND (completed_at IS NULL OR completed_at > ?)", start + d*interval, start + d*interval])
        else 
          @items[d] = current_user.tasks.count(:conditions => ["created_at < ? AND (completed_at IS NULL OR completed_at > ?)", start + d*interval, start + d*interval])
        end
        
        @dates[d] = tz.utc_to_local(start + d * interval - 1.hour).strftime(tick) if(d % step == 0)
        @range[0] ||= @items[d]
        @range[1] ||= @items[d]
        @range[0] = @items[d] if @range[0] > @items[d]
        @range[1] = @items[d] if @range[1] < @items[d]

          
      end
    when 4
        # Active Tasks
    when 5
        # Schedule
    end

    render :update do |page|
      case @widget.widget_type
      when 0
        page.replace_html "content_#{@widget.dom_id}", :partial => 'tasks/task_list', :locals => { :tasks => @items }
      when 1
        page.replace_html "content_#{@widget.dom_id}", :partial => 'activities/project_overview'
      when 2
        page.replace_html "content_#{@widget.dom_id}", :partial => 'activities/recent_work'
      when 3
        page.replace_html "content_#{@widget.dom_id}", :partial => 'widgets/widget_3'
      end

      page.call("updateTooltips")
      
    end

  end

  def edit
    begin
      @widget = Widget.find(params[:id], :conditions => ["company_id = ? AND user_id = ?", current_user.company_id, current_user.id])
    rescue
      render :nothing => true
      return
    end

    render :update do |page|
      page << "if(! $('config-#{@widget.dom_id}' ) ) {"
      page.insert_html :before, "content_#{@widget.dom_id}", :partial => "widget_#{@widget.widget_type}_config"
      page.visual_effect :slide_down, "config-#{@widget.dom_id}"
      page << "} else {"
      page.visual_effect :highlight, "config-#{@widget.dom_id}"
      page << "}"
    end
  end

  def update
    begin
      @widget = Widget.find(params[:id], :conditions => ["company_id = ? AND user_id = ?", current_user.company_id, current_user.id])
    rescue
      render :nothing => true
      return
    end

    if @widget.update_attributes(params[:widget])
      render :update do |page|
        page.remove "config-#{@widget.dom_id}"
        page.replace_html "name-#{@widget.dom_id}", _(@widget.name)
        page << "new Ajax.Request('/widgets/show/#{@widget.id}', {asynchronous:true, evalScripts:true, onComplete:function(request){Element.hide('loading');portal.refreshHeights();}, onLoading:function(request){Element.show('loading');}});"
      end
    end
  end
  
  def save_order
    [0,1,2].each do |c|
      pos = 0
      if params["widget_col_#{c}"]
        params["widget_col_#{c}"].each do |id|
          w = current_user.widgets.find(id.split(/-/)[1])
          w.column = c
          w.position = pos
          w.save
          pos += 1
        end
      end
    end 
    render :nothing => true
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
        page.hide "content_#{@widget.dom_id}"
        page << "Element.removeClassName($('indicator-#{@widget.dom_id}'), 'widget-open');"
        page << "Element.addClassName($('indicator-#{@widget.dom_id}'), 'widget-collapsed');"
      else 
        page.show "content_#{@widget.dom_id}"
        page << "Element.removeClassName($('indicator-#{@widget.dom_id}'), 'widget-collapsed');"
        page << "Element.addClassName($('indicator-#{@widget.dom_id}'), 'widget-open');"
      end
      page << "portal.refreshHeights();"
    end
    
    @widget.save
    
  end
end
