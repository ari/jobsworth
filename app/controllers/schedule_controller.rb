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
        due_date -= 1.days
        due_date -= 1.days if due_date.wday == 6
        due_date -= 2.days if due_date.wday == 0
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

  def users_gantt_free(dates, t, date, rev = false)
    free = true
    t.users.each do |u|
      next unless free
      
      date_check = date
      dur = t.scheduled_minutes_left
      while dur > 0 && free
        day_dur = dur > u.workday_duration ? u.workday_duration : dur

        logger.debug("--> #{t.id}: Checking [#{date_check}] for #{day_dur}")

        dates[date_check] ||= { }
        dates[date_check][u.id] ||= 0
        if dates[date_check][u.id].to_i + day_dur > u.workday_duration
          free = false
          logger.debug("--> #{t.id}: Not free..")
        end
        
        date_check += 1.day
        if date_check.wday == 6
          date_check += 2.days
        end
        if date_check.wday == 0
          date_check += 1.days
        end

        
        dur -= day_dur if free

        logger.debug("--> #{t.id}: #{dur} left to find...")

      end
    end 
    free
  end
  
  def users_gantt_mark(dates, t, date, rev = false)
    end_date = date
    start_date = date.midnight
    t.users.each do |u|
      dur = t.scheduled_minutes_left
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

  def schedule_direction(dates, t, before = nil, after = nil)
    if t.scheduled_date || before || after

      day = nil
      day = (t.scheduled_date).midnight if t.scheduled_date

      day ||= before
      day ||= after
      
      rev = after.nil? ? true : false

      day, rev = override_day(t, day, before, after, rev)

      if day < current_user.tz.now.midnight
        day =  current_user.tz.now.midnight
        rev = false
        logger.debug "--> #{t.id}[##{t.task_num}] forwards due to #{day} < #{current_user.tz.now.midnight}"
      end
      
      logger.info("--> #{t.id}[##{t.task_num}]}: [#{t.scheduled_minutes_left}] [#{t.scheduled_date}] => #{day} : #{rev ? "backwards" : "forwards"}")
    else 
      day = (current_user.tz.now.midnight)
      rev = false

      override_day(t,day,before,after, rev)

      logger.debug "--> #{t.id}[##{t.task_num}] forwards due to no due date"
    end
    
    rev
    
  end

  def schedule_collect_deps(deps, seen, t, rev = false)

#    return deps[t.id] if deps.keys.include?(t.id)
    return [t] if seen.include?(t)

    seen << t

    my_deps = []
    
    unless rev
    end
    

    my_deps << t unless t.done?
    if t.milestone && t.milestone.scheduled_date
      t.dependants.each do |d|
        my_deps += schedule_collect_deps(deps, seen, d, rev)
      end
    else 
      t.dependencies.each do |d|
        my_deps += schedule_collect_deps(deps, seen, d, rev)
      end
    end 

    seen.pop

    my_deps.compact!
    my_deps.uniq!
    
    deps[t.id] = my_deps if my_deps.size > 0
    logger.debug("--> #{t.id} my_deps[#{my_deps.collect{ |dep| "#{dep.id}[##{dep.task_num}]" }.join(',')}] #{rev}")
    my_deps
  end

  def override_day(t, day, before, after, rev)

    logger.debug "--> #{t.id} override got day[#{day.to_s}], before[#{before}], after[#{after}], due[#{t.scheduled_due_at}], #{rev}"

    days = ((t.scheduled_minutes_left) / current_user.workday_duration).to_i
    rem = t.scheduled_minutes_left - (days * current_user.workday_duration)

    dur = days.days + rem.minutes
    if dur > 7.days
      dur += (dur/7.days) * 2.days
    end

    if rev
      
      if (before && before < day) && (t.scheduled_due_at.nil? || before < t.scheduled_due_at)
        day = (before - days.days - rem.minutes).midnight
        logger.debug "--> #{t.id} force before #{day}"
        rev = true
      elsif (t.scheduled_due_at && before.nil?) || (before && t.scheduled_due_at && t.scheduled_due_at < before) || (before && t.scheduled_date && t.scheduled_date < before)
        day = t.scheduled_due_at ? t.scheduled_due_at.midnight : t.scheduled_date.midnight
        
        logger.debug "--> #{t.id} force before #{day} [due] "
        
#        if day.wday == 6
#          day -= 1.days
#          dur += 1.days
#        end 
        if day.wday == 0
          day -= 1.days
          dur += 2.days
        end 

        day -= rem.minutes

        while days > 0
          if day.wday == 0
            day -= 2.days
            dur += 2.days
          elsif day.wday == 6
            day -= 1.days
            dur += 2.days
            days -= 1
          else 
            day -= 1.day
            days -= 1
          end 
          logger.debug "--> #{t.id} force before #{day} - #{days} left [due] "
        end

        
        logger.debug "--> #{t.id} force before #{day.wday} -> #{(day+dur).wday} [due] "
        
        if day.wday == 6
          day -= 2.days
        end 
        if day.wday == 0
          day -= 2.days 
        end 

        logger.debug "--> #{t.id} force before #{day} -> #{(day+dur)} [due] "
      else 
        if day.wday == 0
          day -= 1.days
          dur += 2.days
        end 

        day -= rem.minutes

        while days > 0
          if day.wday == 0
            day -= 2.days
            dur += 2.days
          elsif day.wday == 6
            day -= 1.days
            dur += 2.days
            days -= 1
          else 
            day -= 1.day
            days -= 1
          end 
          logger.debug "--> #{t.id} force before #{day} - #{days} left"
        end

      end 
    end

    unless rev
      if after && after > day && (t.scheduled_due_at.nil? || after < (t.scheduled_due_at + days.days + rem.minutes))
        day = after.midnight
        logger.debug "--> #{t.id} force after #{day}"
        rev = false
      elsif (t.scheduled_due_at && after.nil? ) || (after && t.scheduled_due_at && (t.scheduled_due_at - days.days - rem.minutes ) < after)
        day = (t.scheduled_due_at.midnight - days.days - rem.minutes).midnight
        logger.debug "--> #{t.id} force after #{day} [due]"
        rev = true
      end
    end

    if rev
      day -= 1.days if day.wday == 6
      day -= 2.days if day.wday == 0
    else 
      day += 2.days if day.wday == 6
      day += 1.days if day.wday == 0
    end

    
    day = Time.now.utc.midnight if day < Time.now.utc.midnight
    
    logger.debug "--> #{t.id} override returned day[#{day.to_s}], #{rev}]"

    [day.midnight,rev]
  end
  
  def schedule_gantt(dates,t, before = nil, after = nil)

    logger.info "--> #{t.id} scheduling #{"before " + before.to_s if before}#{"after " + after.to_s if after}"


    rev =  schedule_direction(dates,t,before, after)

    @deps ||= {}
    @seen ||= []
    
    schedule_collect_deps(@deps, @seen, t, rev) 

#    rescheduled = @deps[t.id].size > 1

    logger.info "--> #{t.id} deps: #{@deps[t.id].size}[#{@deps[t.id].collect{|d| d.task_num }.join(',')}] #{rev}" unless @deps[t.id].blank?

    range = []
    min_start = max_start = nil

#    if rev
    my_deps = @deps[t.id].slice!( @deps[t.id].rindex(t) .. -1 ) rescue []
#    else 
#      my_deps = @deps[t.id].slice!( 0 .. @deps[t.id].rindex(t) )
#    end
    
    #    @deps[t.id] -= my_deps
    
    while !my_deps.blank? 
      d = rev ? my_deps.pop : my_deps.pop
      next if d.id == t.id
      if rev
        before = min_start.midnight if min_start && (before.nil? || min_start.midnight < before)
      else 
        after = max_start.midnight if max_start && (after.nil? || max_start.midnight > after)
      end
       
#      break unless rev
      
      logger.info "--> #{t.id}[##{t.task_num}] => depends on #{d.id}[##{d.task_num}]"
        
      if rev
        range = schedule_task(dates, d, min_start, nil)
      else 
        range = schedule_task(dates, d, nil, max_start)
      end
      
      logger.debug "--> #{t.id} min_start/max_start #{range.inspect}"
      
      min_start ||= range[0].midnight if range[0]
      min_start = range[0].midnight if range[0] && range[0] < min_start
      
      max_start ||= range[1] if range[1]
      max_start = range[1] if range[1] && range[1] > max_start
      
      logger.debug("--> #{t.id} min_start #{min_start}")
      logger.debug("--> #{t.id} max_start #{max_start}")
      
    end


    rev =  schedule_direction(dates, t, before, after) #if rescheduled

    day = (t.scheduled_date).midnight if t.scheduled_date
    day ||= Time.now.utc.midnight

    if min_start && min_start < day && rev
      before = min_start.midnight 
      after = nil
    elsif max_start && max_start > day && !rev
      after = max_start.midnight 
      before = nil
    end 
    
    logger.debug "--> #{t.id} scheduling got day[#{day.to_s}], before[#{before}], after[#{after}], due[#{t.scheduled_due_at}] - #{rev ? "backwards" : "forwards"}"
    day, rev = override_day(t, day, before, after, rev)
    logger.debug "--> #{t.id} scheduling got adjusted day[#{day.to_s}], before[#{before}], after[#{after}], due[#{t.scheduled_due_at}] - #{rev ? "backwards" : "forwards"}"


    if t.scheduled_minutes_left == 0
      return [day,day]
    end

    found = false
    logger.debug "--> #{t.id} scheduling looking #{day.to_s} #{rev ? "backwards" : "forwards"}"

    while found == false
      found = true
      
      if users_gantt_free(dates, t, day)
        day, end_date = users_gantt_mark(dates, t, day)
        if t.users.empty?
          end_date = day + t.scheduled_minutes_left.minutes
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
            logger.debug("--> switching direction #{t.id}")
            
            if day.wday == 6
              day += 2.days
            end
            if day.wday == 0
              day += 1.days
            end
            
            
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

  def schedule_task(dates, t, before = nil, after = nil)
    return [@start[t.id], @end[t.id]] if @start.keys.include?(t.id) || @stack.include?(t.id)

    @stack << t.id 
    
    range = schedule_gantt(@dates, t, before, after )

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
    
    logger.info "== #{t.id}[##{t.task_num}] [#{format_duration(t.scheduled_minutes_left, current_user.duration_format, current_user.workday_duration, current_user.days_per_week)}] : #{@start[t.id]} -> #{@end[t.id]}"
    @stack.pop
    
    return range
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

    @range = [Time.now.utc.midnight, 1.month.since.utc.midnight]

    @milestone_start = { }
    @milestone_end = { }
    
    start_date = current_user.tz.now.midnight + 8.hours

    tasks = @tasks.select{ |t| t.scheduled_due_at } # all tasks with due dates
    
    
    @milestones = @tasks.select{ |t| t.scheduled_due_at.nil? && t.milestone && t.milestone.scheduled_date }.reverse # all tasks with milestone with due date
    tasks += @milestones.select{ |t| t.dependencies.size == 0 && t.dependants.size == 0}
    tasks += @milestones.select{ |t| t.dependencies.size > 0 && t.dependants.size == 0}
    tasks += @milestones.select{ |t| t.dependencies.size > 0 && t.dependants.size > 0}
    tasks += @milestones.select{ |t| t.dependencies.size == 0 && t.dependants.size > 0}

    non_due = @tasks.reject{ |t| t.scheduled_due_at } # all tasks without due date
    tasks += non_due.select{ |t| t.dependencies.size == 0 && t.dependants.size > 0}
    tasks += non_due.select{ |t| t.dependencies.size > 0 && t.dependants.size > 0}
    tasks += non_due.select{ |t| t.dependencies.size > 0 && t.dependants.size == 0}
    tasks += non_due.select{ |t| t.dependencies.size == 0 && t.dependants.size == 0}
    
    @stack = []
    
    tasks.each do |t|
      t.dependencies.each do |d|
        schedule_task(@dates,d)
      end
      schedule_task(@dates,t)
    end
    
  end

  def gantt_reset
    projects = current_user.projects.select{ |p| current_user.can?(p, 'prioritize')}.collect(&:id).join(',')
    projects = "0" if projects.nil? || projects.length == 0

    Task.update_all("scheduled=0, scheduled_at=NULL, scheduled_duration = 0", ["tasks.project_id IN (#{projects}) AND tasks.completed_at IS NULL"])

    projects = current_user.projects.select{ |p| current_user.can?(p, 'milestone')}.collect(&:id).join(',')
    projects = "0" if projects.nil? || projects.length == 0

    Milestone.update_all("scheduled=0, scheduled_at=NULL", ["milestones.project_id IN (#{projects}) AND milestones.completed_at IS NULL"])
    flash['notice'] = _('Schedule reverted')

    render :update do |page|
      page.redirect_to :action => 'gantt'
    end 

  end 

  def gantt_save

    projects = current_user.projects.select{ |p| current_user.can?(p, 'prioritize')}.collect(&:id).join(',')
    projects = "0" if projects.nil? || projects.length == 0

    tasks = Task.find(:all, :conditions => ["tasks.project_id IN (#{projects}) AND tasks.completed_at IS NULL AND scheduled=1"])
    tasks.each do |t|
      body = ""
      if t.scheduled_at != t.due_at
        old_name = "None"
        old_name = current_user.tz.utc_to_local(t.due_at).strftime_localized("%A, %d %B %Y") unless t.due_at.nil?

        new_name = "None"
        new_name = current_user.tz.utc_to_local(t.scheduled_at).strftime_localized("%A, %d %B %Y") unless t.scheduled_at.nil?

        body << "- <strong>Due</strong>: #{old_name} -> #{new_name}\n"
        t.due_at = t.scheduled_at
      end 
      if t.scheduled_duration.to_i != t.duration.to_i
        body << "- <strong>Estimate</strong>: #{worked_nice(t.duration).strip} -> #{worked_nice(t.scheduled_duration)}\n"
        t.duration = t.scheduled_duration
      end 

      if body != ""
        worklog = WorkLog.new
        worklog.log_type = EventLog::TASK_MODIFIED
        worklog.user = current_user
        worklog.company = t.project.company
        worklog.customer = t.project.customer
        worklog.project = t.project
        worklog.task = t
        worklog.started_at = Time.now.utc
        worklog.duration = 0
        worklog.body = body
        worklog.save

        if(params['notify'].to_i == 1)
          Notifications::deliver_changed( :updated, t, current_user, body.gsub(/<[^>]*>/,'')) rescue nil
        end 

        Juggernaut.send( "do_update(0, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => t.id)}');", ["tasks_#{current_user.company_id}"])
      end 

      t.scheduled_at = nil
      t.scheduled_duration = 0
      t.scheduled = false
      t.save
    end 

    projects = current_user.projects.select{ |p| current_user.can?(p, 'milestone')}.collect(&:id).join(',')
    projects = "0" if projects.nil? || projects.length == 0

    milestones = Milestone.find(:all, :conditions => ["milestones.project_id IN (#{projects}) AND milestones.completed_at IS NULL AND scheduled=1"])
    milestones.each do |m|
      if m.due_at != m.scheduled_at
        m.due_at = m.scheduled_at
        if(params['notify'].to_i == 1)
          Notifications::deliver_milestone_changed(current_user, m, 'updated', m.due_at) rescue nil
        end 
      end 
      m.scheduled_at = nil
      m.scheduled = false
      m.save
    end 

    Juggernaut.send( "do_update(0, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{current_user.company_id}"])

    flash['notice'] = _('Schedule saved')
    render :update do |page|
      page.redirect_to :action => 'gantt'
    end 
  end 

  def reschedule
    begin
      @task = Task.find(params[:id], :conditions => ["tasks.project_id IN (#{current_project_ids}) AND tasks.company_id = '#{current_user.company_id}'"] )
    rescue
      render :nothing => true
      return
    end 

    unless @task.scheduled?
      @task.scheduled_duration = @task.duration
      @task.scheduled_at = @task.due_at
      @task.scheduled = true
    end 
    
    if params[:duration]
      @task.scheduled_duration = parse_time(params[:duration], true)
    end 
    
    if params[:due] && params[:due].length > 0
      begin
        due = DateTime.strptime( params[:due], current_user.date_format )
        @task.scheduled_at = tz.local_to_utc(due.to_time + 1.day - 1.minute) unless due.nil?
      rescue
        render :update do |page|
          page["due-#{@task.dom_id}"].value = (@task.scheduled_at ? @task.scheduled_at.strftime_localized(current_user.date_format) : "")
        end
        return
      end 
    elsif params[:due]
      @task.scheduled_at = nil
    end

    
    @task.save


    gantt
    
    render :update do |page|
      page["duration-#{@task.dom_id}"].value = worked_nice(@task.scheduled_duration)
      page["due-#{@task.dom_id}"].value = (@task.scheduled_at ? @task.scheduled_at.strftime_localized(current_user.date_format) : "")

      page << "$('width-#{@task.dom_id}').setStyle({ backgroundColor:'#{gantt_color(@task)}'});"

      milestones = { }
      
      @tasks.each do |t|
        page << "$('offset-#{t.dom_id}').setStyle({ left:'#{gantt_offset(@start[t.id])}'});"
        page << "$('width-#{t.dom_id}').setStyle({ width:'#{gantt_width(@start[t.id],@end[t.id])}'});"
        page << "$('width-#{t.dom_id}').setStyle({ backgroundColor:'#{gantt_color(t)}'});"
        milestones[t.milestone_id] = t.milestone if t.milestone_id.to_i > 0
      end
      
      milestones.values.each do |m|
        page.replace_html "duration-#{m.dom_id}", worked_nice(m.duration)
        if m.scheduled_at
          page << "$('offset-due-#{m.dom_id}').setStyle({ left:'#{gantt_offset(m.scheduled_at.midnight.to_time)}'});"
        else 
          page << "$('offset-due-#{m.dom_id}').setStyle({ left:'#{gantt_offset(@milestone_end[m.id])}'});"
        end
        
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
    
    unless @milestone.scheduled?
      @milestone.scheduled_at = @milestone.due_at
      @milestone.scheduled = true
    end 

    if params[:due] && params[:due].length > 0
      begin
        due = DateTime.strptime( params[:due], current_user.date_format )
        @milestone.scheduled_at = tz.local_to_utc(due.to_time + 1.day - 1.minute) unless due.nil?
      rescue
        render :update do |page|
          page["due-#{@milestone.dom_id}"].value = (@milestone.scheduled_at ? @milestone.scheduled_at.strftime_localized(current_user.date_format) : "")
        end
        return
      end 
    elsif params[:due]
      @milestone.scheduled_at = nil
    end

    @milestone.save

    gantt
    
    render :update do |page|
      page["due-#{@milestone.dom_id}"].value = (@milestone.scheduled_at ? @milestone.scheduled_at.strftime_localized(current_user.date_format) : "")

      milestones = { }
      
      @tasks.each do |t|
        page << "$('offset-#{t.dom_id}').setStyle({ left:'#{gantt_offset(@start[t.id])}'});"
        page << "$('offset-#{t.dom_id}').setStyle({ width:'#{gantt_width(@start[t.id],@end[t.id]).to_i + 500}px'});"
        page << "$('width-#{t.dom_id}').setStyle({ width:'#{gantt_width(@start[t.id],@end[t.id])}'});"
        page << "$('width-#{t.dom_id}').setStyle({ backgroundColor:'#{gantt_color(t)}'});"
        milestones[t.milestone_id] = t.milestone if t.milestone_id.to_i > 0
      end

      milestones.values.each do |m|
        page.replace_html "duration-#{m.dom_id}", worked_nice(m.duration)
        if m.scheduled_at
          page << "$('offset-due-#{m.dom_id}').setStyle({ left:'#{gantt_offset(m.scheduled_at.midnight.to_time)}'});"
        else 
          page << "$('offset-due-#{m.dom_id}').setStyle({ left:'#{gantt_offset(@milestone_end[m.id])}'});"
        end
        page << "$('offset-#{m.dom_id}').setStyle({ left:'#{gantt_offset(@milestone_start[m.id])}'});"
        page << "$('offset-#{m.dom_id}').setStyle({ width:'#{gantt_width(@milestone_start[m.id], @milestone_end[m.id]).to_i + 500}px'});"
        page << "$('width-#{m.dom_id}').setStyle({ width:'#{gantt_width(@milestone_start[m.id], @milestone_end[m.id])}'});"
      end
      
    end
  end

  def gantt_drag
    begin
      if params[:id].include?('-due-')
        @milestone = Milestone.find(params[:id].split("-").last, :conditions => ["milestones.project_id IN (#{current_project_ids})"] )
      else 
        @task = Task.find(params[:id].split("-").last, :conditions => ["tasks.project_id IN (#{current_project_ids}) AND tasks.company_id = '#{current_user.company_id}'"] )
      end 
    rescue 
      render :nothing => true
      return
    end 
    
    x = params[:x].to_i
    x = 0 if x < 0

    start_date = Time.now.utc.midnight + (x / 16).days
    end_date = start_date + ((params[:w].to_i - 501)/16).days + 1.day
    
    if @milestone
      unless @milestone.scheduled?
        @milestone.scheduled_at = @milestone.due_at
        @milestone.scheduled = true
      end 

      @milestone.scheduled_at = start_date
      @milestone.save
    else 
      unless @task.scheduled?
        @task.scheduled_duration = @task.duration
        @task.scheduled_at = @task.due_at
        @task.scheduled = true
      end 

      @task.scheduled_at = end_date
      @task.save
    end 

    gantt
    
    render :update do |page|
      if @milestone
        page["due-#{@milestone.dom_id}"].value = (@milestone.scheduled_at ? @milestone.scheduled_at.strftime_localized(current_user.date_format) : "")
      else 
        page["due-#{@task.dom_id}"].value = (@task.scheduled_at ? @task.scheduled_at.strftime_localized(current_user.date_format) : "")
        page["duration-#{@task.dom_id}"].value = worked_nice(@task.scheduled_duration)
        page << "$('width-#{@task.dom_id}').setStyle({ backgroundColor:'#{gantt_color(@task)}'});"
      end 

      milestones = { }
      
      @tasks.each do |t|
        page << "$('offset-#{t.dom_id}').setStyle({ left:'#{gantt_offset(@start[t.id])}'});"
        page << "$('width-#{t.dom_id}').setStyle({ width:'#{gantt_width(@start[t.id],@end[t.id])}'});"
        page << "$('width-#{t.dom_id}').setStyle({ backgroundColor:'#{gantt_color(t)}'});"
        milestones[t.milestone_id] = t.milestone if t.milestone_id.to_i > 0
      end
      
      milestones.values.each do |m|
        page.replace_html "duration-#{m.dom_id}", worked_nice(m.duration)
        if m.scheduled_at
          page << "$('offset-due-#{m.dom_id}').setStyle({ left:'#{gantt_offset(m.scheduled_at.midnight.to_time)}'});"
        else 
          page << "$('offset-due-#{m.dom_id}').setStyle({ left:'#{gantt_offset(@milestone_end[m.id])}'});"
        end
        page << "$('offset-#{m.dom_id}').setStyle({ left:'#{gantt_offset(@milestone_start[m.id])}'});"
        page << "$('offset-#{m.dom_id}').setStyle({ width:'#{gantt_width(@milestone_start[m.id], @milestone_end[m.id]).to_i + 500}px'});"
        page << "$('width-#{m.dom_id}').setStyle({ width:'#{gantt_width(@milestone_start[m.id], @milestone_end[m.id])}'});"
      end
    end
    
  end
  

  def gantt_dragging
    begin

      if params[:id].include?('-due-')
        @milestone = Milestone.find(params[:id].split("-").last, :conditions => ["milestones.project_id IN (#{current_project_ids})"] )
      else 
        @task = Task.find(params[:id].split("-").last, :conditions => ["tasks.project_id IN (#{current_project_ids}) AND tasks.company_id = '#{current_user.company_id}'"] )
      end 
    rescue 
      render :nothing => true
      return
    end 
    
    x = params[:x].to_i
    x = 0 if x < 0

    start_date = Time.now.utc.midnight + (x / 16).days
    end_date = start_date + ((params[:w].to_i - 501)/16).days + 1.day

    if @milestone
      @milestone.scheduled_at = start_date
      render :update do |page|
        page["due-#{@milestone.dom_id}"].value = (@milestone.scheduled_at ? @milestone.scheduled_at.strftime_localized(current_user.date_format) : "")
      end
    else 
      @task.scheduled_at = end_date
      render :update do |page|
        page["due-#{@task.dom_id}"].value = (@task.scheduled_at ? @task.scheduled_at.strftime_localized(current_user.date_format) : "")
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
    if t.scheduled_overdue?
      if t.scheduled?
        "#f00"
      else 
        "#f66"
      end 
    elsif t.scheduled? && t.scheduled_date
      if @end[t.id] && @end[t.id] > t.scheduled_date.to_time
        "#f00"
      elsif t.overworked?
        "#ff9900"
      elsif t.started? 
        "#1e7002"
      else 
        "#00f"
      end 
    else 
      if t.scheduled_date && @end[t.id] && @end[t.id] > t.scheduled_date.to_time
        "#f66"
      elsif t.overworked?
       "#ff9900"
      elsif t.started? 
       "#76a670"
     else 
       "#88f"
     end 
    end
  end

end
