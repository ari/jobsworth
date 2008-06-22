# Generate a calendar showing completed and due Tasks for a Company
# TODO: Simple Events
class ScheduleController < ApplicationController

  helper_method :gantt_offset
  helper_method :gantt_width
  helper_method :gantt_color
  
  def list

    today = Time.now.to_date

    @year = params[:year] unless params[:year].nil?
    @month = params[:month] unless params[:month].nil?

    @year ||= today.year
    @month ||= today.month


    # Find all tasks for the current month, should probably be adjusted to use
    # TimeZone for current User instead of UTC.
    @tasks = Task.find(:all, :order => 'tasks.duration desc, tasks.name', :conditions => ["tasks.project_id IN (#{current_project_ids}) AND tasks.company_id = '#{current_user.company_id}' AND ((tasks.due_at is NOT NULL AND tasks.due_at > '#{@year}-#{@month}-01 00:00:00' AND tasks.due_at < '#{@year}-#{@month}-31 23:59:59') OR (tasks.completed_at is NOT NULL AND tasks.completed_at > '#{@year}-#{@month}-01 00:00:00' AND tasks.completed_at < '#{@year}-#{@month}-31 23:59:59'))", ], :include => [:milestone] )
    @milestones = Milestone.find(:all, :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", current_user.company_id])
    @dates = {}

    # Mark milestones
    @milestones.each do |m|
      unless m.due_at.nil?
        @dates[tz.utc_to_local(m.due_at).to_date] ||= []
        @dates[tz.utc_to_local(m.due_at).to_date] << m
      end
    end

    # Mark all tasks
    @tasks.each do |t|
      due_date = tz.utc_to_local(t.due_at).to_date unless t.due_at.nil?
      due_date ||= tz.utc_to_local(t.completed_at).to_date unless t.completed_at.nil?


      @dates[due_date] ||= []

      duration = t.duration

      days = (duration / (60*8)) - 1

      days = 0 if days < 0

      found = false
      slot = 0
      until found
        found = true

        done = days
        d = -1

        while done >= 0
          d += 1
          next if ((due_date - d).wday == 0 || (due_date - d).wday == 6) && !(due_date.wday == 0 || due_date.wday == 6)
          #            logger.info "Checking #{due_date-d} for slot #{slot}"
          unless @dates[due_date - d].nil? || @dates[due_date - d][slot].nil?
              found = false
            #              logger.info "Conflict.."
          end
          done -= 1
        end
        slot += 1 unless found
      end

      while days >= 0
        days -= 1
        @dates[due_date] ||= []
        @dates[due_date][slot] = t
        due_date -= 1
        due_date -= 1 if due_date.wday == 6
        due_date -= 2 if due_date.wday == 0
      end

    end

  end

  # New event
  def new
  end

  # Edit event
  def edit
  end

  # Create event
  def create
  end

  # Update event
  def update
  end

  # Delte event
  def delete
  end

  # Refresh calendar on Event addition / task completion
  def refresh
  end

  def users_gantt_free(dates, t, date, rev = false )
    free = true
    t.users.each do |u|
      next unless free
      
      date_check = date
      dur = t.minutes_left
      while dur > 0 && free
        day_dur = dur > u.workday_duration ? u.workday_duration : dur

        dates[date_check] ||= { }
        dates[date_check][u.id] ||= 0
        if dates[date_check][u.id].to_i + day_dur > u.workday_duration
          free = false
        end
        
        date_check += 1.day
        if date_check.wday == 6
          date_check += 2.days
        end
        if date_check.wday == 0
          date_check += 1.days
        end
        
        dur -= day_dur
      end
    end 
    free
  end
  
  def users_gantt_mark(dates, t, date, rev = false)
    end_date = date
    start_date = date.midnight
    t.users.each do |u|
      dur = t.minutes_left
      day = date + dates[date][u.id].minutes
      start_date = day if day > start_date
      while dur > 0
        day_dur = dur > u.workday_duration ? u.workday_duration : dur
      
        dates[day.midnight][u.id] += day_dur
        if (dur <= u.workday_duration)
          day += dur.minutes
        end

        end_date = day if end_date < day
        
        day += 1.day
        if day.wday == 6
          day += 2.days
        end
        if day.wday == 0
          day += 1.days
        end

        dur -= day_dur
      end
    end
    [start_date,end_date]
  end
  
  def schedule_gantt(dates,t)
    if t.due_date
      days = (t.minutes_left) / current_user.workday_duration
      rem = t.minutes_left - (days * current_user.workday_duration)
      
      day = (t.due_date.midnight - days.days - rem.minutes).midnight

      if day.wday == 0
        day -= 2.days
      end
      if day.wday == 6
        day -= 1.days
      end
      
      logger.info("#{t.id}: [#{t.minutes_left}] [#{t.due_date}] => #{day}")
      rev = true

      if day < current_user.tz.now.midnight
        day =  current_user.tz.now.midnight
        rev = false
      end
    else 
      day = (current_user.tz.now.midnight)
      rev = false
    end

    if t.minutes_left == 0
      return [day,day]
    end

    found = false
    while found == false
      found = true
      
      if users_gantt_free(dates, t, day)
        range = users_gantt_mark(dates, t, day)
        day = range[0]
        end_date = range[1]
        if t.users.empty?
          end_date = day + t.minutes_left.minutes
        end
        
        return [day, end_date]
      else 
        found = false

        if rev 
          day -= 1.day
          if day.wday == 0
            day -= 2.days
          end
          if day.wday == 6
            day -= 1.days
          end
          
          if day < current_user.tz.now.midnight
            day = current_user.tz.now.midnight
            rev = false
          end
          
        else 
          day += 1.day
          if day.wday == 6
            day += 2.days
          end
          if day.wday == 0
            day += 1.days
          end

        end

      end
    end
    
    
  end
  
  def gantt

    sort = "tasks.milestone_id IS NOT NULL, tasks.milestone_id <> 0, milestones.due_at IS NOT NULL desc, milestones.due_at, milestones.name, tasks.due_at IS NOT NULL desc, CASE WHEN (tasks.due_at IS NULL AND milestones.due_at IS NULL) THEN 1 ELSE 0 END, CASE WHEN (tasks.due_at IS NULL AND tasks.milestone_id IS NOT NULL) THEN milestones.due_at ELSE tasks.due_at END, tasks.priority + tasks.severity_id desc, tasks.name"
    params[:filter_by] ||= " "
    filter = case params[:filter_by][0..0]
             when 'c'
               "AND tasks.project_id IN (#{current_user.projects.find(:all, :conditions => ["customer_id = ?", params[:filter_by][1..-1]]).collect(&:id).compact.join(',') } )"
             when 'p'
               "AND tasks.project_id = #{@widget.filter_by[1..-1]}"
             when 'm'
               "AND tasks.milestone_id = #{@widget.filter_by[1..-1]}"
             when 'u'
               "AND tasks.project_id = #{@widget.filter_by[1..-1]} AND tasks.milestone_id IS NULL"
             else 
               ""
             end

    @tasks = Task.find(:all, :include => [:milestone, :project, :users], :conditions => ["tasks.project_id IN (#{current_project_ids}) AND tasks.completed_at IS NULL AND projects.completed_at IS NULL #{filter}"], :order => sort)

    @dates = { }
    
    @start = { }
    @end = { }

    @range = [Time.now.utc.midnight]

    @milestone_start = { }
    @milestone_end = { }
    
    start_date = current_user.tz.now.midnight + 8.hours

    tasks = @tasks.select{ |t| t.due_at }
    tasks += @tasks.select{ |t| t.due_at.nil? && t.milestone && t.milestone.due_at }.reverse
    tasks += @tasks.reject{ |t| t.due_date }
    
    tasks.each do |t|
      
      range = schedule_gantt(@dates, t)

      @start[t.id] = range[0]
      @end[t.id] = range[1]

      @range[0] ||= range[0]
      @range[0] = range[0] if range[0] < @range[0]

      @range[1] ||= range[1]
      @range[1] = range[1] if range[1] > @range[1]

      if t.milestone_id.to_i > 0
        @milestone_start[t.milestone_id] ||= range[0]
        @milestone_start[t.milestone_id]   = range[0] if @milestone_start[t.milestone_id] > range[0]
        
        @milestone_end[t.milestone_id] ||= range[1]
        @milestone_end[t.milestone_id]   = range[1] if @milestone_end[t.milestone_id] < range[1]
      end
      
      logger.info "#{t.id} [#{format_duration(t.minutes_left, current_user.duration_format, current_user.workday_duration, current_user.days_per_week)}] : #{@start[t.id]} -> #{@end[t.id]}"
      
    end
    
  end

  def reschedule
    begin
      @task = Task.find(params[:id], :conditions => ["tasks.project_id IN (#{current_project_ids}) AND tasks.company_id = '#{current_user.company_id}'"] )
    rescue
      render :nothing => true
      return
    end 
    
    if params[:duration]
      @task.duration = parse_time(params[:duration], true)
    end 
    
    if params[:due] && params[:due].length > 0
      begin
        @task.due_at = DateTime.strptime( params[:due], current_user.date_format )
      rescue
        render :update do |page|
          page["due-#{@task.dom_id}"].value = (@task.due_at ? @task.due_at.strftime_localized(current_user.date_format) : "")
        end
        return
      end 
    elsif params[:due]
      @task.due_at = nil
    end
    
    @task.save

    Juggernaut.send( "do_update(0, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])

    gantt
    
    render :update do |page|
      page["duration-#{@task.dom_id}"].value = worked_nice(@task.duration)
      page["due-#{@task.dom_id}"].value = (@task.due_at ? @task.due_at.strftime_localized(current_user.date_format) : "")

      page << "$('width-#{@task.dom_id}').setStyle({ backgroundColor:'#{gantt_color(@task)}'});"

      milestones = { }
      
      @tasks.each do |t|
        page << "$('offset-#{t.dom_id}').setStyle({ left:'#{gantt_offset(@start[t.id])}'});"
        page << "$('width-#{t.dom_id}').setStyle({ width:'#{gantt_width(@start[t.id],@end[t.id])}'});"
        milestones[t.milestone_id] = t.milestone if t.milestone_id.to_i > 0
      end
      
      milestones.values.each do |m|
        page.replace_html "duration-#{m.dom_id}", worked_nice(m.duration)
        page << "$('offset-#{m.dom_id}').setStyle({ left:'#{gantt_offset(@milestone_start[m.id])}'});"
        page << "$('offset-#{m.dom_id}').setStyle({ width:'#{gantt_width(@milestone_start[m.id], @milestone_end[m.id]).to_i + 500}px'});"
        page << "$('width-#{m.dom_id}').setStyle({ width:'#{gantt_width(@milestone_start[m.id], @milestone_end[m.id])}'});"
      end
      
    end
  end

  def reschedule_milestone
    begin
      @milestone = Milestone.find(params[:id], :conditions => ["milestones.project_id IN (#{current_project_ids})"] )
    rescue
      render :nothing => true
      return
    end 
    
    if params[:due] && params[:due].length > 0
      begin
        @milestone.due_at = DateTime.strptime( params[:due], current_user.date_format )
      rescue
        render :update do |page|
          page["due-#{@milestone.dom_id}"].value = (@milestone.due_at ? @milestone.due_at.strftime_localized(current_user.date_format) : "")
        end
        return
      end 
    elsif params[:due]
      @milestone.due_at = nil
    end
    
    @milestone.save

    gantt
    
    render :update do |page|
      page["due-#{@milestone.dom_id}"].value = (@milestone.due_at ? @milestone.due_at.strftime_localized(current_user.date_format) : "")
      page << "$('offset-#{@milestone.dom_id}').setStyle({ left:'#{gantt_offset(@milestone_start[@milestone.id])}'});"
      page << "$('offset-#{@milestone.dom_id}').setStyle({ width:'#{gantt_width(@milestone_start[@milestone.id], @milestone_end[@milestone.id]).to_i + 500}px'});"
      page << "$('width-#{@milestone.dom_id}').setStyle({ width:'#{gantt_width(@milestone_start[@milestone.id], @milestone_end[@milestone.id])}'});"

      if @milestone.due_at
        page << "$('offset-due-#{@milestone.dom_id}').setStyle({ left:'#{gantt_offset(@milestone.due_at.midnight.to_time)}'});"
      else 
        page << "$('offset-due-#{@milestone.dom_id}').setStyle({ left:'#{gantt_offset(@milestone_end[@milestone.id])}'});"
      end

      milestones = { }
      
      @tasks.each do |t|
        page << "$('offset-#{t.dom_id}').setStyle({ left:'#{gantt_offset(@start[t.id])}'});"
        page << "$('offset-#{t.dom_id}').setStyle({ width:'#{gantt_width(@start[t.id],@end[t.id]).to_i + 500}px'});"
        page << "$('width-#{t.dom_id}').setStyle({ width:'#{gantt_width(@start[t.id],@end[t.id])}'});"
        milestones[t.milestone_id] = t.milestone if t.milestone_id.to_i > 0
      end

      milestones.values.each do |m|
        page.replace_html "duration-#{m.dom_id}", worked_nice(m.duration)
        page << "$('offset-#{m.dom_id}').setStyle({ left:'#{gantt_offset(@milestone_start[m.id])}'});"
        page << "$('offset-#{m.dom_id}').setStyle({ width:'#{gantt_width(@milestone_start[m.id], @milestone_end[m.id]).to_i + 500}px'});"
        page << "$('width-#{m.dom_id}').setStyle({ width:'#{gantt_width(@milestone_start[m.id], @milestone_end[m.id])}'});"
      end
      
    end
  end
  
  
  def gantt_offset(d)
    days = (d.to_i - Time.now.utc.midnight.to_i) / 1.day
    rem = ((d.to_i - Time.now.utc.midnight.to_i) - days.days) / 1.minute
    w = days * 16.0 + (rem.to_f / current_user.workday_duration) * 16.0
    w = 0 if w < 0
    "#{w.to_i}px"
  end

  def gantt_width(s,e)
    days = (e.to_i - s.to_i) / 1.day
    rem = ((e.to_i - s.to_i) - days.days) / 1.minute

    w = days * 16.0 + (rem.to_f / current_user.workday_duration) * 16.0
    w = 2 if w < 2

    "#{w.to_i}px"
  end
  
  def gantt_color(t)
    if t.overdue?
      "#f66"
    elsif t.due_at? 
     if t.overworked?
       "#ff9900"
     elsif t.started? 
       "#1e7002"
     else 
       "#00f"
     end 
    else 
      if t.overworked?
       "#ff9900"
      elsif t.started? 
       "#76a670"
     else 
       "#88f"
     end 
    end
  end

end
