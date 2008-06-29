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
      dur = t.minutes_left
      while dur > 0 && free
        day_dur = dur > u.workday_duration ? u.workday_duration : dur

        logger.info("--> #{t.id}: Checking [#{date_check}] for #{day_dur}")

        dates[date_check] ||= { }
        dates[date_check][u.id] ||= 0
        if dates[date_check][u.id].to_i + day_dur > u.workday_duration
          free = false
          logger.info("--> #{t.id}: Not free..")
        end
        
        date_check += 1.day
        if date_check.wday == 6
          date_check += 2.days
        end
        if date_check.wday == 0
          date_check += 1.days
        end

        
        dur -= day_dur if free

        logger.info("--> #{t.id}: #{dur} left to find...")

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

  def schedule_direction(dates, t, before = nil, after = nil)
    days = ((t.minutes_left) / current_user.workday_duration).to_i
    rem = t.minutes_left - (days * current_user.workday_duration)

    if t.due_date || before || after

      day = nil
      day = (t.due_date.midnight - days.days - rem.minutes).midnight if t.due_date

      day ||= before
      day ||= after
      
      rev = after.nil? ? true : false

      day, rev = override_day(t, day, before, after, rev)
      
      if rev
        if day.wday == 0
          day -= 2.days
        end
        if day.wday == 6
          day -= 1.days
        end
      else 
        if day.wday == 0
          day += 1.days
        end
        if day.wday == 6
          day += 2.days
        end
      end

      if day < current_user.tz.now.midnight
        day =  current_user.tz.now.midnight
        rev = false
        logger.info "--> #{t.id}[##{t.task_num}] forwards due to #{day} < #{current_user.tz.now.midnight}"
      end
      
      logger.info("--> #{t.id}[##{t.task_num}]}: [#{t.minutes_left}] [#{t.due_date}] => #{day} : #{rev ? "backwards" : "forwards"}")
    else 
      day = (current_user.tz.now.midnight)
      rev = false

      override_day(t,day,before,after, rev)

      if day.wday == 0
        day += 1.days 
      end
      if day.wday == 6
        day += 2.days
      end

      logger.info "--> #{t.id}[##{t.task_num}] forwards due to no due date"
    end
    
    [day,rev]
    
  end

  def schedule_collect_deps(deps, seen, t, rev = false)

#    return deps[t.id] if deps.keys.include?(t.id)
    return [t] if seen.include?(t)

    seen << t

    my_deps = []
    
    unless rev
    end
    

    my_deps << t
    if t.milestone && t.milestone.due_at
      t.dependants.each do |d|
        my_deps += schedule_collect_deps(deps, seen, d, rev)
      end
    else 
      t.dependencies.each do |d|
        my_deps += schedule_collect_deps(deps, seen, d, rev)
      end
    end 

    seen.pop

    my_deps.uniq!
    
    deps[t.id] = my_deps if my_deps.size > 0
    logger.info("--> #{t.id} my_deps[#{my_deps.collect{ |dep| "#{dep.id}[##{dep.task_num}]" }.join(',')}] #{rev}")
    my_deps
  end

  def override_day(t, day, before, after, rev)

    logger.info "--> #{t.id} override got day[#{day.to_s}], before[#{before}], after[#{after}], due[#{t.due_at}], #{rev}"

    days = ((t.minutes_left) / current_user.workday_duration).to_i
    rem = t.minutes_left - (days * current_user.workday_duration)

    dur = days.days + rem.minutes
    if dur > 7.days
      dur += (dur/7.days) * 2.days
    end

    if rev
      
      if (before && before < day) && (t.due_at.nil? || before < t.due_at)
        day = (before.midnight - days.days - rem.minutes).midnight
        logger.info "--> #{t.id} force before #{day}"
        rev = true
      elsif (t.due_at && before.nil?) || (before && t.due_at && t.due_at < before)
        day = t.due_at.midnight - 1.days
        day -= rem.minutes
        logger.info "--> #{t.id} force before #{day} [due] "
        
        if day.wday == 0
          day -= 2.days
          dur += 2.days
        end 
        if day.wday == 6
          day -= 1.days
          dur += 1.days
        end 

        while days > 1
          day -= 1.day
          
          logger.info "--> #{t.id} force before #{day} - #{days} left [due] "
          
          if day.wday == 0
            day -= 2.days
            dur += 2.days
          end 
          if day.wday == 6
            day -= 2.days
            dur += 2.days
          end 

          logger.info "--> #{t.id} force before #{day} - #{days} left [due] "
          days -= 1
        end

        
        logger.info "--> #{t.id} force before #{day.wday} -> #{(day+dur).wday} [due] "
        
        if day.wday == 6
          day -= 2.days
        end 
        if day.wday == 0
          day -= 2.days 
        end 

        logger.info "--> #{t.id} force before #{day} -> #{(day+dur)} [due] "

        
        if (day + dur).wday == 1
          day -= 1.days
        end 

        logger.info "--> #{t.id} force before #{day.wday} -> #{(day+dur).wday} [due] "
 
#          day -= 2.days
#        end
        
        logger.info "--> #{t.id} force before #{day} [due]"
        rev = true
      end 
    end

    unless rev
      if after && after > day && (t.due_at.nil? || after < (t.due_at + days.days + rem.minutes))
        day = after.midnight
        logger.info "--> #{t.id} force after #{day}"
        rev = false
      elsif (t.due_at && after.nil? ) || (after && t.due_at && (t.due_at - days.days - rem.minutes ) < after)
        day = (t.due_at.midnight - days.days - rem.minutes).midnight
        logger.info "--> #{t.id} force after #{day} [due]"
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

    
    
    logger.info "--> #{t.id} override returned day[#{day.to_s}], #{rev}]"

    [day.midnight,rev]
  end
  
  def schedule_gantt(dates,t, before = nil, after = nil)

    logger.info "--> #{t.id} scheduling #{"before " + before.to_s if before}#{"after " + after.to_s if after}"


    day, rev =  schedule_direction(dates,t,before, after)

    @deps ||= {}
    @seen ||= []
    
    schedule_collect_deps(@deps, @seen, t, rev) 

    rescheduled = @deps[t.id].size > 0 

    logger.info "--> #{t.id} deps: #{@deps[t.id].size}[#{@deps[t.id].collect{|d| d.task_num }.join(',')}] #{rev}" unless @deps[t.id].blank?

    range = []
    min_start = max_start = nil

#    if rev
      my_deps = @deps[t.id].slice!( @deps[t.id].rindex(t) .. -1 )
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
      
      logger.info "--> #{t.id} min_start/max_start #{range.inspect}"
      
      min_start ||= range[0].midnight if range[0]
      min_start = range[0].midnight if range[0] && range[0] < min_start
      
      max_start ||= range[1] if range[1]
      max_start = range[1] if range[1] && range[1] > max_start
      
      logger.info("--> #{t.id} min_start #{min_start}")
      logger.info("--> #{t.id} max_start #{max_start}")
      
    end


    day, rev =  schedule_direction(dates, t, before, after)

    if min_start && min_start < day && rev
      before = min_start.midnight 
      after = nil
    elsif max_start && max_start > day && !rev
      after = max_start.midnight 
      before = nil
    end 
    
    logger.info "--> #{t.id} scheduling got day[#{day.to_s}], before[#{before}], after[#{after}], due[#{t.due_at}] - #{rev ? "backwards" : "forwards"}"

    day, rev = override_day(t, day, before, after, rev)
    
    if t.minutes_left == 0
      return [day,day]
    end

    found = false
    logger.info "--> #{t.id} scheduling looking #{day.to_s} #{rev ? "backwards" : "forwards"}"

    while found == false
      found = true
      
      if users_gantt_free(dates, t, day)
        day, end_date = users_gantt_mark(dates, t, day)
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
            logger.info("--> switching direction #{t.id}")
            
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
    
    logger.info "== #{t.id}[##{t.task_num}] [#{format_duration(t.minutes_left, current_user.duration_format, current_user.workday_duration, current_user.days_per_week)}] : #{@start[t.id]} -> #{@end[t.id]}"
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

    tasks = @tasks.select{ |t| t.due_at } # all tasks with due dates
    
    
    milestones = @tasks.select{ |t| t.due_at.nil? && t.milestone && t.milestone.due_at }.reverse # all tasks with milestone with due date
    tasks += milestones.select{ |t| t.dependencies.size == 0 && t.dependants.size == 0}
    tasks += milestones.select{ |t| t.dependencies.size > 0 && t.dependants.size == 0}
    tasks += milestones.select{ |t| t.dependencies.size > 0 && t.dependants.size > 0}
    tasks += milestones.select{ |t| t.dependencies.size == 0 && t.dependants.size > 0}

    non_due = @tasks.reject{ |t| t.due_date } # all tasks without due date
    tasks += non_due.select{ |t| t.dependencies.size > 0 && t.dependants.size == 0}
    tasks += non_due.select{ |t| t.dependencies.size > 0 && t.dependants.size > 0}
    tasks += non_due.select{ |t| t.dependencies.size == 0 && t.dependants.size > 0}
    tasks += non_due.select{ |t| t.dependencies.size == 0 && t.dependants.size == 0}
    
    @stack = []
    
    tasks.each do |t|
      t.dependencies.each do |d|
        schedule_task(@dates,d)
      end
      schedule_task(@dates,t)
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
        page << "$('width-#{t.dom_id}').setStyle({ backgroundColor:'#{gantt_color(t)}'});"
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
        page << "$('width-#{t.dom_id}').setStyle({ backgroundColor:'#{gantt_color(t)}'});"
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
    elsif t.due_date 
      if @end[t.id] > t.due_date.to_time
      "#f66"
      elsif t.overworked?
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
