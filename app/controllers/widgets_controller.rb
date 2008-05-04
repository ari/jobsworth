class WidgetsController < ApplicationController

  def show
    begin
      @widget = Widget.find(params[:id], :conditions => ["company_id = ? AND user_id = ?", current_user.company_id, current_user.id])
    rescue
      render :nothing => true
      return
    end

    unless @widget.configured?
      render :update do |page|
        page.insert_html :before, "content_#{@widget.dom_id}", :partial => "widget_#{@widget.widget_type}_config"
        page.show "config-#{@widget.dom_id}"
      end
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
      unless @widget.mine?
        @items = Task.find(:all, :conditions => ["tasks.project_id IN (#{current_project_ids}) AND tasks.completed_at IS NULL AND tasks.company_id = #{current_user.company_id} AND (tasks.hide_until IS NULL OR tasks.hide_until < '#{tz.now.utc.to_s(:db)}') AND (tasks.milestone_id NOT IN (#{completed_milestone_ids}) OR tasks.milestone_id IS NULL)"],  :order => order, :include => [:tags, :work_logs, :milestone, { :project => :customer }, :dependencies, :dependants, :users, :work_logs, :todos], :limit => @widget.number  )
      else 
        @items = current_user.tasks.find(:all, :conditions => ["tasks.project_id IN (#{current_project_ids}) AND tasks.completed_at IS NULL AND (tasks.hide_until IS NULL OR tasks.hide_until < '#{tz.now.utc.to_s(:db)}') AND (tasks.milestone_id NOT IN (#{completed_milestone_ids}) OR tasks.milestone_id IS NULL)"],  :order => order, :include => [:tags, :work_logs, :milestone, { :project => :customer }, :dependencies, :dependants, :work_logs, :todos], :limit => @widget.number  )
      end
    when 1
      # Project List
      @projects = current_user.projects.find(:all, :order => 't1_r2, projects.name', :conditions => ["projects.completed_at IS NULL"], :include => [ :customer, :milestones])
      @completed_projects = current_user.completed_projects.size
    when 2
      # Activities
      @activities = EventLog.find(:all, :order => "event_logs.created_at DESC", :limit => @widget.number, 
          :conditions => ["company_id = ? AND (event_logs.project_id IN ( #{current_project_ids} ) OR event_logs.project_id IS NULL)", current_user.company_id]
        )
    when 3
      # Tasks Graph
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

      if @widget.filter_by?
        filter = case @widget.filter_by[0..0]
        when 'c'
           "AND tasks.project_id IN (#{current_user.projects.find(:all, :conditions => ["customer_id = ?", @widget.filter_by[1..-1]]).collect(&:id).compact } )"
        when 'p'
           "AND tasks.project_id = #{@widget.filter_by[1..-1]}"
        when 'm'
           "AND tasks.milestone_id = #{@widget.filter_by[1..-1]}"
        when 'u'
          "AND tasks.project_id = #{@widget.filter_by[1..-1]} AND tasks.milestone_id IS NULL"
        else 
          ""
        end
      end
      
      @items = []
      @dates = []
      @range = []
      0.upto(range * step) do |d|
          
        unless @widget.mine?
          @items[d] = current_user.company.tasks.count(:conditions => ["project_id IN (#{current_project_ids}) AND created_at < ? AND (completed_at IS NULL OR completed_at > ?) #{filter}", start + d*interval, start + d*interval])
        else 
          @items[d] = current_user.tasks.count(:conditions => ["tasks.project_id IN (#{current_project_ids}) AND created_at < ? AND (completed_at IS NULL OR completed_at > ?) #{filter}", start + d*interval, start + d*interval])
        end
        
        @dates[d] = tz.utc_to_local(start + d * interval - 1.hour).strftime(tick) if(d % step == 0)
        @range[0] ||= @items[d]
        @range[1] ||= @items[d]
        @range[0] = @items[d] if @range[0] > @items[d]
        @range[1] = @items[d] if @range[1] < @items[d]
      end
    when 4
      # Burndown
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

      if @widget.filter_by?
        filter = case @widget.filter_by[0..0]
        when 'c'
           "AND tasks.project_id IN (#{current_user.projects.find(:all, :conditions => ["customer_id = ?", @widget.filter_by[1..-1]]).collect(&:id).compact } )"
        when 'p'
           "AND tasks.project_id = #{@widget.filter_by[1..-1]}"
        when 'm'
           "AND tasks.milestone_id = #{@widget.filter_by[1..-1]}"
        when 'u'
          "AND tasks.project_id = #{@widget.filter_by[1..-1]} AND tasks.milestone_id IS NULL"
        else 
          ""
        end
      end

      @items = []
      @dates = []
      @range = []
      velocity = 0
      0.upto(range * step) do |d|
        
        unless @widget.mine?
          @items[d] = current_user.company.tasks.sum('duration', :conditions => ["project_id IN (#{current_project_ids}) AND created_at < ? AND (completed_at IS NULL OR completed_at > ?) #{filter}", start + d*interval, start + d*interval]).to_f / current_user.workday_duration
          worked = current_user.company.tasks.sum('work_logs.duration', :conditions => ["tasks.project_id IN (#{current_project_ids}) AND tasks.created_at < ? AND (tasks.completed_at IS NULL OR tasks.completed_at > ?) #{filter} AND tasks.duration > 0 AND work_logs.started_at < ?", start + d*interval, start + d*interval, start + d*interval], :include => :work_logs).to_f / current_user.workday_duration
          @items[d] = (@items[d] - worked > 0) ? (@items[d] - worked) : 0
          
        else 
          @items[d] = current_user.tasks.sum('duration', :conditions => ["tasks.project_id IN (#{current_project_ids}) AND created_at < ? AND (completed_at IS NULL OR completed_at > ?) #{filter}", start + d*interval, start + d*interval]).to_f / current_user.workday_duration
          worked = current_user.tasks.sum('work_logs.duration', :conditions => ["tasks.project_id IN (#{current_project_ids}) AND tasks.created_at < ? AND (tasks.completed_at IS NULL OR tasks.completed_at > ?) #{filter} AND tasks.duration > 0 AND work_logs.started_at < ?", start + d*interval, start + d*interval, start + d*interval], :include => :work_logs).to_f / current_user.workday_duration
          @items[d] = (@items[d] - worked > 0) ? (@items[d] - worked) : 0
        end
        
        @dates[d] = tz.utc_to_local(start + d * interval - 1.hour).strftime(tick) if(d % step == 0)
        @range[0] ||= @items[d]
        @range[1] ||= @items[d]
        @range[0] = @items[d] if @range[0] > @items[d]
        @range[1] = @items[d] if @range[1] < @items[d]

      end
      
      velocity = (@items[0] - @items[-1]) / ((interval * range * step) / 1.day)
      velocity = velocity * (interval / 1.day)
      
      logger.info("Velocity: #{velocity}")

      start = @items[0]
      
      @velocity = []
      0.upto(range * step) do |d|
        @velocity[d] = start - velocity * d
      end 
      
    when 5
      # Burnup
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

      if @widget.filter_by?
        filter = case @widget.filter_by[0..0]
        when 'c'
           "AND tasks.project_id IN (#{current_user.projects.find(:all, :conditions => ["customer_id = ?", @widget.filter_by[1..-1]]).collect(&:id).compact } )"
        when 'p'
           "AND tasks.project_id = #{@widget.filter_by[1..-1]}"
        when 'm'
           "AND tasks.milestone_id = #{@widget.filter_by[1..-1]}"
        when 'u'
          "AND tasks.project_id = #{@widget.filter_by[1..-1]} AND tasks.milestone_id IS NULL"
        else 
          ""
        end
      end

      @items  = []
      @totals = []
      @dates  = []
      @range  = []
      velocity = 0
      0.upto(range * step) do |d|
        
        unless @widget.mine? 
          @totals[d]  = current_user.company.tasks.sum('duration', :conditions => ["project_id IN (#{current_project_ids}) #{filter} AND created_at < ?", start + d*interval]).to_f / current_user.workday_duration
          @totals[d] += current_user.company.tasks.sum('work_logs.duration', :conditions => ["tasks.project_id IN (#{current_project_ids}) #{filter} AND tasks.created_at < ? AND tasks.duration = 0 AND work_logs.started_at < ?", start + d*interval, start + d*interval], :include => :work_logs).to_f / current_user.workday_duration

          @items[d] = current_user.company.tasks.sum('tasks.duration', :conditions => ["tasks.project_id IN (#{current_project_ids}) #{filter}  AND (completed_at IS NOT NULL AND completed_at < ?) AND tasks.created_at < ?  AND tasks.duration > 0", start + d*interval, start + d*interval]).to_f / current_user.workday_duration
          @items[d] += current_user.company.tasks.sum('work_logs.duration', :conditions => ["tasks.project_id IN (#{current_project_ids}) #{filter} AND tasks.created_at < ? AND (tasks.completed_at IS NULL OR tasks.completed_at > ?) AND work_logs.started_at < ?", start + d*interval, start + d*interval, start + d*interval], :include => :work_logs).to_f / current_user.workday_duration
        else 
          @totals[d]  = current_user.tasks.sum('duration', :conditions => ["tasks.project_id IN (#{current_project_ids}) #{filter} AND created_at < ?", start + d*interval]).to_f / current_user.workday_duration
          @totals[d] += current_user.tasks.sum('work_logs.duration', :conditions => ["tasks.project_id IN (#{current_project_ids}) #{filter} AND tasks.created_at < ? AND tasks.duration = 0 AND work_logs.started_at < ?", start + d*interval, start + d*interval], :include => :work_logs).to_f / current_user.workday_duration
          
          @items[d] = current_user.tasks.sum('tasks.duration', :conditions => ["tasks.project_id IN (#{current_project_ids}) #{filter} AND (completed_at IS NOT NULL AND completed_at < ?) AND tasks.created_at < ?  AND tasks.duration > 0", start + d*interval, start + d*interval]).to_f / current_user.workday_duration
          @items[d] += current_user.tasks.sum('work_logs.duration', :conditions => ["tasks.project_id IN (#{current_project_ids}) #{filter} AND tasks.created_at < ?  AND (tasks.completed_at IS NULL OR tasks.completed_at > ?) AND work_logs.started_at < ?", start + d*interval, start + d*interval, start + d*interval], :include => :work_logs).to_f / current_user.workday_duration
        end
        
        @dates[d] = tz.utc_to_local(start + d * interval - 1.hour).strftime(tick) if(d % step == 0)
        @range[0] ||= @items[d]
        @range[1] ||= @items[d]
        @range[0] = @items[d] if @range[0] > @items[d]
        @range[1] = @items[d] if @range[1] < @items[d]

        @range[0] = @totals[d] if @range[0] > @totals[d]
        @range[1] = @totals[d] if @range[1] < @totals[d]

      end
      
      velocity = (@items[0] - @items[-1]) / ((interval * range * step) / 1.day)
      velocity = velocity * (interval / 1.day)
      
      logger.info("Velocity: #{velocity}")

      start = @items[0]
      
      @velocity = []
      0.upto(range * step) do |d|
        @velocity[d] = start - velocity * d
      end 
    when 6
      # Schedule
    when 7 
      # Chat 
    end

    render :update do |page|
      case @widget.widget_type
      when 0
        page.replace_html "content_#{@widget.dom_id}", :partial => 'tasks/task_list', :locals => { :tasks => @items }
      when 1
        page.replace_html "content_#{@widget.dom_id}", :partial => 'activities/project_overview'
      when 2
        page.replace_html "content_#{@widget.dom_id}", :partial => 'activities/recent_work'
      when 3..7
        page.replace_html "content_#{@widget.dom_id}", :partial => "widgets/widget_#{@widget.widget_type}"
      end

      page.call("updateTooltips")
      page.call("portal.refreshHeights")
      
    end

  end

  
  
  def add
    render :update do |page|
      page << "if(! $('add-widget' ) ) {"
      page.insert_html :top, "left_col", :partial => "widgets/add"
      page.visual_effect :appear, "add-widget"
      page << "} else {"
      page.visual_effect :highlight, "add-widget"
      page << "}"
    end
  end

  def destroy
    begin
      @widget = Widget.find(params[:id], :conditions => ["company_id = ? AND user_id = ?", current_user.company_id, current_user.id])
    rescue
      render :nothing => true
      return
    end
    render :update do |page|
      page << "var widget = $('#{@widget.dom_id}').widget;"
      page << "portal.remove(widget);"
    end
    @widget.destroy
  end
  
  def create
    @widget = Widget.new(params[:widget])
    @widget.user = current_user
    @widget.company = current_user.company
    @widget.configured = false
    @widget.column = 0
    @widget.position = 0
    @widget.collapsed = false
    
    unless @widget.save
      render :update do |page|
        page.visual_effect :shake, 'add-widget'
      end
      return
    else 
      render :update do |page|
        page.remove 'add-widget'
        page << "var widget = new Xilinus.Widget('widget', '#{@widget.dom_id}');"
        page << "var title = '<div style=\"float:right;display:none;\" class=\"widget-menu\"><a href=\"#\" onclick=\"new Ajax.Request(\\\'/widgets/edit/#{@widget.id}\\\', {asynchronous:true, evalScripts:true}); return false;\"><img src=\"/images/configure.png\" border=\"0\"/></a><a href=\"#\" onclick=\"new Ajax.Request(\\\'/widgets/destroy/#{@widget.id}\\\', {asynchronous:true, evalScripts:true}); return false;\"><img src=\"/images/delete.png\" border=\"0\"/></a></div>';"

        page << "title += '<div><a href=\"#\" id=\"indicator-#{@widget.dom_id}\" class=\"widget-open\" onclick=\"new Ajax.Request(\\\'/widgets/toggle_display/#{@widget.id}\\\',{asynchronous:true, evalScripts:true, onComplete:function(request){Element.hide(\\\'loading\\\');portal.refreshHeights();}, onLoading:function(request){Element.show(\\\'loading\\\');}});\">&nbsp;</a>';"
        page << "title += '" + render_to_string(:partial => "widgets/widget_#{@widget.widget_type}_header").gsub(/'/,'\\\\\'').split(/\n/).join + "</div>';"
        page.<< "widget.setTitle(title);"
        page << "widget.setContent('<span class=\"optional\">#{h(_('Please configure the widget'))}</span>');"
        page << "portal.add(widget, #{@widget.column});"
        page << "new Ajax.Request('/widgets/show/#{@widget.id}', {asynchronous:true, evalScripts:true, onComplete:function(request){Element.hide('loading');portal.refreshHeights();}, onLoading:function(request){Element.show('loading');}});"

        page << "updateTooltips();"
        page << "portal.refreshHeights();"
      end 
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

    @widget.configured = true
    
    if @widget.update_attributes(params[:widget])
      render :update do |page|
        page.remove "config-#{@widget.dom_id}"
        page.replace_html "name-#{@widget.dom_id}", _(@widget.name)
        page << "new Ajax.Request('/widgets/show/#{@widget.id}', {asynchronous:true, evalScripts:true, onComplete:function(request){Element.hide('loading');}, onLoading:function(request){Element.show('loading');}});"
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
