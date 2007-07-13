# Handle tasks for a Company / User
# Author:: Erlend Simonsen (mailto:admin@clockingit.com)
#
class TasksController < ApplicationController
 cache_sweeper :cache_sweeper, :only => [:create, :update, :destroy, :ajax_hide, :ajax_restore,
    :ajax_check, :ajax_uncheck, :start_work_ajax, :stop_work, :swap_work_ajax, :save_log, :update_log,
    :cancel_work_ajax, :destroy_log ]

  def new
    @projects = User.find(session[:user].id).projects.find(:all, :order => 'name', :conditions => ["completed_at IS NULL"]).collect {|c| [ "#{c.name} / #{c.customer.name}", c.id ] if session[:user].can?(c, 'create')  }.compact unless session[:user].projects.nil?

    if @projects.nil? || @projects.empty?
      flash['notice'] = _("You need to create a project to hold your tasks, or get access to create tasks in an existing project...")
      redirect_to :controller => 'projects', :action => 'new'
    else
      @task = Task.new
      @task.duration = 0
      @tags = Tag.top_counts({ :company_id => session[:user].company_id, :project_ids => current_project_ids, :filter_hidden => session[:filter_hidden], :filter_milestone => session[:filter_milestone]})
    end
  end

  def list
    # Subscribe to the juggernaut channel for Task updates
    session[:channels] += ["tasks_#{session[:user].company_id}"]

    @tags = {}
    @tags.default = 0
    @tags_total = 0
    if session[:filter_project].to_i == 0
      project_ids = current_project_ids
    else
      project_ids = session[:filter_project]
    end


    filter = ""

    if session[:filter_user].to_i > 0
      task_ids = User.find(session[:filter_user].to_i).tasks.collect { |t| t.id }.join(',')
      if task_ids == ''
        filter = "tasks.id IN (0) AND "
      else
        filter = "tasks.id IN (#{task_ids}) AND "
      end
    elsif session[:filter_user].to_i < 0
      not_task_ids = Task.find(:all, :select => "tasks.*", :joins => "LEFT OUTER JOIN task_owners t_o ON tasks.id = t_o.task_id", :readonly => false, :conditions => ["tasks.company_id = ? AND t_o.id IS NULL", session[:user].company_id]).collect { |t| t.id }.join(',')
      if not_task_ids == ''
        filter = "tasks.id = 0 AND "
      else
        filter = "tasks.id IN (#{not_task_ids}) AND " if not_task_ids != ""
      end
    end

    if session[:filter_milestone].to_i > 0
      filter << "tasks.milestone_id = #{session[:filter_milestone]} AND "
    elsif session[:filter_milestone].to_i < 0
      filter << "(tasks.milestone_id IS NULL OR tasks.milestone_id = 0) AND "
    end

    unless session[:filter_status].to_i == -1 || session[:filter_status].to_i == -2
      if session[:filter_status].to_i == 0
        filter << "(tasks.status = 0 OR tasks.status = 1) AND "
      else
        filter << "tasks.status = #{session[:filter_status].to_i} AND "
      end
    end

    if session[:filter_status].to_i == -2
      filter << "tasks.hidden = 1 AND "
    else
      filter << "tasks.hidden = 0 AND "
    end

    unless session[:filter_type].to_i == -1
      filter << "tasks.type_id = #{session[:filter_type].to_i} AND "
    end

    unless session[:filter_customer].to_i == 0
      filter << "projects.customer_id = #{session[:filter_customer]} AND "
    end

    filter << "(tasks.milestone_id NOT IN (#{completed_milestone_ids}) OR tasks.milestone_id IS NULL) AND "


    if params[:tag] && params[:tag].length > 0
      # Looking for tasks based on tags
      @selected_tags = params[:tag].downcase.split(',').collect{|t| t.strip}
      @tasks = Task.tagged_with(@selected_tags, { :company_id => session[:user].company_id, :project_ids => project_ids, :filter_hidden => session[:filter_hidden], :filter_user => session[:filter_user], :filter_milestone => session[:filter_milestone], :filter_status => session[:filter_status], :filter_customer => session[:filter_customer]})
    else
      # Looking for tasks based on filters
      @selected_tags = []
      @tasks = Task.find(:all, :conditions => [filter + "tasks.company_id = #{session[:user].company_id} AND tasks.project_id IN (#{project_ids})"],  :order => " tasks.completed_at IS NOT NULL, tasks.completed_at desc, tasks.priority + tasks.severity_id desc, CASE WHEN (tasks.due_at IS NULL AND milestones.due_at IS NULL) THEN 1 ELSE 0 END, CASE WHEN (tasks.due_at IS NULL AND tasks.milestone_id IS NOT NULL) THEN milestones.due_at ELSE tasks.due_at END", :include => [:tags, :work_logs, :milestone, :project])
    end

    # Most popular tags, currently unlimited.
    @all_tags = Tag.top_counts({ :company_id => session[:user].company_id, :project_ids => project_ids, :filter_hidden => session[:filter_hidden], :filter_customer => session[:filter_customer]})

    if session[:group_tags].to_i > 0
      @tag_names = @all_tags.collect{|i,j| i}
      @groups = Task.tag_groups(session[:user].company_id, @tag_names, @tasks)
    else
      @groups = [@tasks]
    end


  end

  # Return a json formatted list of options to refresh the Milestone dropdown
  def get_milestones
    @milestones = Milestone.find(:all, :order => 'name', :conditions => ['company_id = ? AND project_id = ? AND completed_at IS NULL', session[:user].company_id, params[:project_id]]).collect{|m| "{\"text\":\"#{m.name}\", \"value\":\"#{m.id}\"}" }.join(',')

    # {"options":[{"value":"1","text":"Test Page"}]}
    res = '{"options":[{"value":"0", "text":"' + _('[None]') + '"}'
    res << ", #{@milestones}" unless @milestones.nil? || @milestones.empty?
    res << ']}'
    render :text => res
  end

  # Return a json formatted list of users to refresh the User dropdown
  # This a bit tricky, as it also updates a JavaScript variable with the current drop-down box.
  def get_owners

    @users = Project.find(params[:project_id]).users.find(:all, :order => 'name' )

    @resource_string = "<option value=\"\">[#{_('No one')}]</option>" + @users.collect{|us| "<option value=\"#{us.id}\">#{us.name}</option>"}.join('')
    @resource_string = @resource_string.split(/\n/).join('').gsub(/'/, "\\\\\'")

    @options = @users.collect{ |u| (' {"text":"' + u.name.gsub(/"/,'\"') + '", "value":"' + u.id.to_s + '"}') }.join( ',' )
    res = '{"options":[{"value":"0", "text":"[None]"}'
    res << ", #{@options}" unless @options.nil? || @options.empty?
    res << ']}'

    render :inline => "#{res}\n<script type=\"text/javascript\">resource = '<select name=\"users[]\">#{@resource_string}</select>';</script>"
  end

  def create

    @task = Task.new(params[:task])

      if !params[:task].nil? && !params[:task][:due_at].nil? && params[:task][:due_at].length > 0

        repeat = @task.parse_repeat(params[:task][:due_at])
        if  repeat != ""
          @task.repeat = repeat
          @task.due_at = tz.local_to_utc(@task.next_repeat_date)
        else
          @task.repeat = nil
          due_date = DateTime.strptime( params[:task][:due_at], session[:user].date_format ) rescue begin
                                                                                                      flash['notice'] = _('Invalid due date ignored.')
                                                                                                      due_date = nil
                                                                                                    end
          @task.due_at = tz.local_to_utc(due_date.to_time + 1.day - 1.minute) unless due_date.nil?
        end
      else
        @task.repeat = nil
      end


    @task.company_id = session[:user].company_id
    @task.duration = parse_time(params[:task][:duration])
    @task.updated_by_id = session[:user].id
    @task.creator_id = session[:user].id
    @task.set_tags(params[:task][:set_tags])
    @task.set_task_num(session[:user].company_id)
    @task.duration = 0 if @task.duration.nil?

    if @task.save

      if params[:watchers]
        params[:watchers].each do |w|
          u = User.find(w.to_i, :conditions => ["company_id = ?", session[:user].company_id])
          n = Notification.new(:user => u, :task => @task)
          n.save
        end
      end

      if params[:users]
        params[:users].each do |o|
          next if o.to_i == 0
          u = User.find(o.to_i, :conditions => ["company_id = ?", session[:user].company_id])
          to = TaskOwner.new(:user => u, :task => @task)
          to.save
        end
      end

      if params[:dependencies]
        params[:dependencies].each do |d|
          next if d.to_i == 0
          t = Task.find(:first, :conditions => ["company_id = ? AND task_num = ?", session[:user].company_id, d.to_i])
          unless t.nil?
            @task.dependencies << t
          end
        end
        @task.save
      end

      if params['task_file'].respond_to?(:original_filename) && params['task_file'].length > 0

        filename = params[:task_file].original_filename
        filename = filename.split("/").last
        filename = filename.split("\\").last
        filename = filename.gsub(/[^a-zA-Z0-9.]/, '_')

        task_file = ProjectFile.new()
        task_file.company = session[:user].company
        task_file.customer = @task.project.customer
        task_file.project = @task.project
        task_file.task_id = @task.id
        task_file.filename = filename
        task_file.name = filename
        task_file.save
        task_file.reload

        File.open(task_file.file_path, "wb", 0777) { |f| f.write( params['task_file'].read ) } rescue begin
                                                                                                        task_file.destroy
                                                                                                        flash['notice'] = _("Permission denied while saving file.")
                                                                                                      end
        task_file.file_size = File.size?( task_file.file_path )
        task_file.save

        #TODO Add notification
      end

      worklog = WorkLog.new
      worklog.user = session[:user]
      worklog.company = @task.project.company
      worklog.customer = @task.project.customer
      worklog.project = @task.project
      worklog.task = @task
      worklog.started_at = Time.now.utc
      worklog.duration = 0
      worklog.log_type = WorkLog::TASK_CREATED
      worklog.body = params[:comment] if (!params[:comment].nil? && params[:comment].length > 0)

      worklog.save
      if params['notify'].to_i == 1
        Notifications::deliver_created( @task, session[:user], params[:comment]) rescue begin end
      end

      return if request.xhr?
      Juggernaut.send( "do_update(#{session[:user].id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{session[:user].company_id}"])
      Juggernaut.send( "do_update(#{session[:user].id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{session[:user].company_id}"])

      flash['notice'] ||= _('Task was successfully created.')
      redirect_from_last
    else
      @projects = User.find(session[:user].id).projects.find(:all, :order => 'name', :conditions => ["completed_at IS NULL"]).collect {|c| [ "#{c.name} / #{c.customer.name}", c.id ] if session[:user].can?(c, 'create')  }.compact unless session[:user].projects.nil?
      @tags = Tag.top_counts({ :company_id => session[:user].company_id, :project_ids => current_project_ids, :filter_hidden => session[:filter_hidden], :filter_milestone => session[:filter_milestone]})
      render_action 'new'
    end
  end

  def view
    @task = Task.find(:first, :conditions => ["project_id IN (#{current_project_ids}) AND task_num = ?", params[:id]])
    redirect_to :action => 'edit', :id => @task.id
  end

  def edit
    @task = Task.find(params[:id], :conditions => ["project_id IN (?)", User.find(session[:user].id).projects.collect{|p|p.id}] )
    @task.due_at = tz.utc_to_local(@task.due_at) unless @task.due_at.nil?
    @tags = Tag.top_counts({ :company_id => session[:user].company_id, :project_ids => current_project_ids, :filter_hidden => session[:filter_hidden], :filter_milestone => session[:filter_milestone]})
    unless @logs = WorkLog.find(:all, :order => "work_logs.started_at desc,work_logs.id desc", :conditions => ["work_logs.task_id = ?", @task.id], :include => [:user, :task, :project])
      @logs = []
    end
    @projects = User.find(session[:user].id).projects.find(:all, :order => 'name', :conditions => ["completed_at IS NULL"]).collect {|c| [ "#{c.name} / #{c.customer.name}", c.id ] if session[:user].can?(c, 'create')  }.compact unless session[:user].projects.nil?
  end

#  def edit_ajax
#    self.edit
#    render :action => 'edit', :layout => false
#  end

  def repeat_task(task)
    @repeat = Task.new
    @repeat.status = 0
    @repeat.project_id = task.project_id
    @repeat.company_id = task.company_id
    @repeat.name = task.name
    @repeat.repeat = task.repeat
    @repeat.requested_by = task.requested_by
    @repeat.creator_id = task.creator_id
    @repeat.type_id = task.type_id
    @repeat.priority = task.priority
    @repeat.severity_id = task.severity_id
    @repeat.set_tags(task.tags.collect{|t| t.name}.join(', '))
    @repeat.set_task_num(session[:user].company_id)
    @repeat.duration = task.duration
    @repeat.notify_emails = task.notify_emails
    @repeat.milestone_id = task.milestone_id
    @repeat.hidden = task.hidden
    @repeat.due_at = @task.due_at
    @repeat.due_at = @repeat.next_repeat_date
    @repeat.description = task.description

    @repeat.save
    @repeat.reload

    task.notifications.each do |w|
      n = Notification.new(:user => w.user, :task => @repeat)
      n.save
    end

    task.task_owners.each do |o|
      to = TaskOwner.new(:user => o.user, :task => @repeat)
      to.save
    end

    task.dependencies.each do |d|
        @repeat.dependencies << d
    end

    @repeat.save

  end

  def update
    projects = User.find(session[:user].id).projects.collect{|p|p.id}

    @task = Task.find(params[:id], :conditions => ["project_id IN (?)", projects], :include => [:tags])
    old_tags = @task.tags.collect {|t| t.name}.join(', ')
    old_deps = @task.dependencies.collect { |t| t.issue_num }.join(', ')
    old_users = @task.users.collect{ |u| u.id}.sort.join(',')
    old_users = "0" if old_users.nil? || old_users.empty?
    old_project_id = @task.project_id
    old_project_name = @task.project.name
    @old_task = @task.clone

    if @task.update_attributes(params[:task])

      if !params[:task].nil? && !params[:task][:due_at].nil? && params[:task][:due_at].length > 0

        repeat = @task.parse_repeat(params[:task][:due_at])
        if  repeat != ""
          @task.repeat = repeat
          @task.due_at = tz.local_to_utc(@task.next_repeat_date)
        else
          @task.repeat = nil
          due_date = DateTime.strptime( params[:task][:due_at], session[:user].date_format ) rescue begin
                                                                                                      flash['notice'] = _('Invalid due date ignored.')
                                                                                                      due_date = nil
                                                                                                    end
          @task.due_at = tz.local_to_utc(due_date.to_time + 1.day - 1.minute) unless due_date.nil?
        end
      else
        @task.repeat = nil
      end

      unless params[:watchers].nil?
        @task.notifications.destroy_all
        params[:watchers].each do |w|
          u = User.find(w.to_i, :conditions => ["company_id = ?", session[:user].company_id])
          n = Notification.new(:user => u, :task => @task)
          n.save
        end
      end

      unless params[:users].nil?
        @task.task_owners.destroy_all
        params[:users].each do |o|
          next if o.to_i == 0
          u = User.find(o.to_i, :conditions => ["company_id = ?", session[:user].company_id])
          to = TaskOwner.new(:user => u, :task => @task)
          to.save
        end
      end

      if params[:dependencies]
        @task.dependencies.delete @task.dependencies
        params[:dependencies].each do |d|
          next if d.to_i == 0
          t = Task.find(:first, :conditions => ["company_id = ? AND task_num = ?", session[:user].company_id, d.to_i])
          unless t.nil?
            @task.dependencies << t
          end
        end
      end

      @task.duration = parse_time(params[:task][:duration]) if (params[:task] && params[:task][:duration])
      @task.updated_by_id = session[:user].id

      if @task.status > 1 && @task.completed_at.nil?
        @task.completed_at = Time.now.utc

        # Repeat this task every X...
        if @task.next_repeat_date != nil

          @task.save
          @task.reload

          repeat_task(@task)
        end
      end

      if @task.status < 2 && !@task.completed_at.nil?
        @task.completed_at = nil
      end
      @task.save

      @task.reload

      body = ""
      if @old_task[:name] != @task[:name]
        body = body + "- <strong>Name</strong>: #{@old_task[:name]} -> #{@task[:name]}\n"
      end

      if @old_task.description != @task.description
        body = body + "- <strong>Description</strong> changed\n"
      end

      if params[:users] && old_users != params[:users].collect{|u| u.to_i}.sort.join(',')

        @task.users.reload

        new_name = @task.users.empty? ? 'Unassigned' : @task.users.collect{ |u| u.name}.join(', ')

        body = body + "- <strong>Assignment</strong>: #{new_name}\n"

        if params['notify'].to_i == 1
          Notifications::deliver_assigned( @task, session[:user], @task.users, old_users, params[:comment] ) rescue begin end
        end

      end

      if old_project_id != @task.project_id
        body = body + "- <strong>Project</strong>: #{old_project_name} -> #{@task.project.name}\n"
        WorkLog.update_all("customer_id = #{@task.project.customer_id}, project_id = #{@task.project_id}", "task_id = #{@task.id}")
      end

      if @old_task.duration != @task.duration
        body = body + "- <strong>Estimate</strong>: #{worked_nice(@old_task.duration).strip} -> #{worked_nice(@task.duration)}\n"
      end

      if @old_task.milestone != @task.milestone
        old_name = "None"
        old_name = @old_task.milestone.name unless @old_task.milestone.nil?

        new_name = "None"
        new_name = @task.milestone.name unless @task.milestone.nil?

        body << "- <strong>Milestone</strong>: #{old_name} -> #{new_name}\n"
      end

      if @old_task.due_at != @task.due_at
        old_name = "None"
        old_name = @old_task.due_at.strftime("%A, %d %B %Y") unless @old_task.due_at.nil?

        new_name = "None"
        new_name = @task.due_at.strftime("%A, %d %B %Y") unless @task.due_at.nil?

        body << "- <strong>Due</strong>: #{old_name} -> #{new_name}\n"
      end


      if @old_task.priority != @task.priority
        body << "- <strong>Priority</strong>: #{@old_task.priority_type} -> #{@task.priority_type}\n"
      end

      if @old_task.severity_id != @task.severity_id
        old_severity = @old_task.severity_type
        new_severity = @task.severity_type

        body << "- <strong>Severity</strong>: #{old_severity} -> #{new_severity}\n"
      end


      if @old_task.type_id != @task.type_id

        body << "- <strong>Type</strong>: #{@old_task.issue_type} -> #{@task.issue_type}\n"
      end

      new_tags = @task.tags.collect {|t| t.name}.join(', ')
      if old_tags != new_tags
        body << "- <strong>Tags</strong>: #{new_tags}\n"
      end

      new_deps = @task.dependencies.collect { |t| t.issue_num}.join(', ')
      if old_deps != new_deps
        body << "- <strong>Dependencies</strong>: #{new_deps}"
      end

      worklog = WorkLog.new
      worklog.log_type = WorkLog::TASK_MODIFIED


      if @old_task.status != @task.status
        body << "- <strong>Status</strong>: #{@old_task.status_type} -> #{@task.status_type}\n"

        worklog.log_type = WorkLog::TASK_COMPLETED if @task.status > 1
        worklog.log_type = WorkLog::TASK_REVERTED if @task.status == 0

        if( @task.status > 1 && @old_task.status != @task.status )
          if params['notify'].to_i == 1
            Notifications::deliver_completed( @task, session[:user], params[:comment] ) rescue begin end
          end
        end

      end


      if params['task_file'].respond_to?(:original_filename) && params['task_file'].length > 0

        filename = params[:task_file].original_filename
        filename = filename.split("/").last
        filename = filename.split("\\").last
        filename = filename.gsub(/[^a-zA-Z0-9.]/, '_')


        task_file = ProjectFile.new()
        task_file.company = session[:user].company
        task_file.customer = @task.project.customer
        task_file.project = @task.project
        task_file.task_id = @task.id
        task_file.filename = filename
        task_file.name = filename
        task_file.file_size = params['task_file'].size
        task_file.save

        task_file.reload

        File.open(task_file.file_path, "wb", 0777) { |f| f.write( params['task_file'].read ) } rescue begin
                                                                                                        task_file.destroy
                                                                                                        flash['notice'] = _("Permission denied while saving file.")
                                                                                                      end

        body << "- <strong>Attached</strong>: #{filename}\n"
      end


      if params[:comment] && params[:comment].length > 0
        worklog.log_type = WorkLog::TASK_COMMENT if body.length ==  0
        if (body.length == 0 and params['notify'].to_i == 1)
          Notifications::deliver_commented( @task, session[:user], params[:comment] ) rescue begin end
        end

        body << "<br/>" if body.length > 0
        body << CGI::escapeHTML(params[:comment])
      end

      if body.length > 0
        worklog.user = session[:user]
        worklog.company = @task.project.company
        worklog.customer = @task.project.customer
        worklog.project = @task.project
        worklog.task = @task
        worklog.started_at = Time.now.utc
        worklog.duration = 0
        worklog.body = body
        worklog.save
      end

      Juggernaut.send( "do_update(#{session[:user].id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{session[:user].company_id}"])
      Juggernaut.send( "do_update(#{session[:user].id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{session[:user].company_id}"])

      return if request.xhr?

      flash['notice'] ||= _('Task was successfully updated.')
      redirect_from_last
    else
      render_action 'edit'
    end
  end

  def update_ajax
    self.update
  end

#  def destroy
#    @task = Task.find(params[:id], :conditions => ["project_id IN (#{current_project_ids})"])
#    @task.work_logs.destroy_all
#    @task.destroy
#
#    return if request.xhr?
#
#    redirect_from_last
#  end

  def ajax_hide
    @task = Task.find(params[:id], :conditions => ["project_id IN (#{current_project_ids})"])

    unless @task.hidden == 1
      @task.hidden = 1
      @task.updated_by_id = session[:user].id
      @task.save

      worklog = WorkLog.new
      worklog.user = session[:user]
      worklog.company = @task.project.company
      worklog.customer = @task.project.customer
      worklog.project = @task.project
      worklog.task = @task
      worklog.started_at = Time.now.utc
      worklog.duration = 0
      worklog.log_type = WorkLog::TASK_ARCHIVED
      worklog.body = ""
      worklog.save
    end

    render :nothing => true
  end

  def ajax_restore
    @task = Task.find(params[:id], :conditions => ["project_id IN (#{current_project_ids})"])
    unless @task.hidden == 0
      @task.hidden = 0
      @task.updated_by_id = session[:user].id
      @task.save

      worklog = WorkLog.new
      worklog.user = session[:user]
      worklog.company = @task.project.company
      worklog.customer = @task.project.customer
      worklog.project = @task.project
      worklog.task = @task
      worklog.started_at = Time.now.utc
      worklog.duration = 0
      worklog.log_type = 1
      worklog.log_type = WorkLog::TASK_RESTORED
      worklog.body = ""
      worklog.save
    end
    render :nothing => true
  end


  def ajax_check
    @task = Task.find(params[:id], :conditions => ["project_id IN (?)", User.find(session[:user].id).projects.collect{|p|p.id}], :include => :project)

    unless @task.completed_at

      @task.completed_at = Time.now.utc
      @task.updated_by_id = session[:user].id
      @task.status = 2
      @task.save
      @task.reload

      if @task.next_repeat_date != nil
          repeat_task(@task)
      end

      worklog = WorkLog.new
      worklog.user = session[:user]
      worklog.company = @task.project.company
      worklog.customer = @task.project.customer
      worklog.project = @task.project
      worklog.task = @task
      worklog.started_at = Time.now.utc
      worklog.duration = 0
      worklog.log_type = WorkLog::TASK_COMPLETED
      worklog.body = ""
      worklog.save

      if session[:user].send_notifications
        Notifications::deliver_completed( @task, session[:user] ) rescue begin end
      end

      Juggernaut.send( "do_update(#{session[:user].id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{session[:user].company_id}"])
      Juggernaut.send( "do_update(#{session[:user].id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{session[:user].company_id}"])
    end

    if session[:history] && session[:history][0] == '/activities/list'
      @projects = User.find(session[:user].id).projects.find(:all, :order => 't1_r2, projects.name', :conditions => ["projects.completed_at IS NULL"], :include => [ :customer, :milestones]);
      @completed_projects = User.find(session[:user].id).projects.find(:all, :conditions => ["projects.completed_at IS NOT NULL"]).size
      @activities = WorkLog.find(:all, :order => "work_logs.started_at DESC", :limit => 25, :conditions => ["work_logs.project_id IN ( #{current_project_ids} )"], :include => [:user, :project, :customer, :task])

      user = User.find(session[:user].id)

      @tasks = user.tasks.find(:all, :conditions => ["tasks.company_id = #{session[:user].company_id} AND tasks.project_id IN (#{current_project_ids}) AND tasks.completed_at IS NULL AND (tasks.milestone_id NOT IN (#{completed_milestone_ids}) OR tasks.milestone_id IS NULL)"],  :order => "tasks.severity_id + tasks.priority desc, CASE WHEN (tasks.due_at IS NULL AND milestones.due_at IS NULL) THEN 1 ELSE 0 END, CASE WHEN (tasks.due_at IS NULL AND tasks.milestone_id IS NOT NULL) THEN milestones.due_at ELSE tasks.due_at END LIMIT 5", :include => [:milestone]  )

      new_filter = ""
      new_filter = "AND tasks.id NOT IN (" + @tasks.collect{ |t| t.id}.join(', ') + ")" if @tasks.size > 0

      @new_tasks = Task.find(:all, :conditions => ["tasks.company_id = #{session[:user].company_id} AND tasks.project_id IN (#{current_project_ids}) #{new_filter} AND tasks.completed_at IS NULL AND (tasks.milestone_id NOT IN (#{completed_milestone_ids}) OR tasks.milestone_id IS NULL)"],  :order => "tasks.created_at desc", :include => [:milestone], :limit => 5  )
    end
  end

  def ajax_uncheck
    @task = Task.find(params[:id], :conditions => ["project_id IN (?)", User.find(session[:user].id).projects.collect{|p|p.id}], :include => :project)

    unless @task.completed_at.nil?

      @task.completed_at = nil
      @task.status = 0
      @task.updated_by_id = session[:user].id
      @task.save

      worklog = WorkLog.new
      worklog.user = session[:user]
      worklog.company = @task.project.company
      worklog.customer = @task.project.customer
      worklog.project = @task.project
      worklog.task = @task
      worklog.started_at = Time.now.utc
      worklog.duration = 0
      worklog.log_type = WorkLog::TASK_REVERTED
      worklog.body = ""
      worklog.save

      if session[:user].send_notifications
        Notifications::deliver_reverted( @task, session[:user] ) rescue begin end
      end

      Juggernaut.send( "do_update(#{session[:user].id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{session[:user].company_id}"])
      Juggernaut.send( "do_update(#{session[:user].id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{session[:user].company_id}"])
    end

  end


  def start_work
    sheet = Sheet.find(:first, :conditions => ["user_id = ?", session[:user].id])

    if sheet
      self.swap_work_ajax
    end

    task = Task.find(params[:id], :conditions => ["company_id = ?", session[:user].company_id])
    sheet = Sheet.new

    sheet.task = task
    sheet.user = session[:user]
    sheet.project = task.project
    sheet.save

    task.status = 1 if task.status == 0
    task.save

    session[:sheet] = sheet


    return if request.xhr?
    redirect_from_last
  end

  def start_work_ajax
    self.start_work
  end

  def start_work_edit_ajax
    self.start_work
  end

  def cancel_work_ajax
    if sheet = Sheet.find(:first, :conditions => ["user_id = ? AND task_id = ?", session[:user].id, session[:sheet].task.id])
      sheet.destroy
    end
    session[:sheet] = nil
    @task = Task.find(params[:id], :conditions => ["company_id = ?", session[:user].company_id])
    return if request.xhr?
    redirect_from_last
  end


  def swap_work_ajax
    if session[:sheet] && sheet = Sheet.find(:first, :conditions => ["user_id = ? AND task_id = ?", session[:user].id, session[:sheet].task.id])

      @old_task = sheet.task
      @old_task.updated_by_id = session[:user].id
      @old_task.save

      worklog = WorkLog.new
      worklog.user = session[:user]
      worklog.company = session[:user].company
      worklog.project = sheet.project
      worklog.task = sheet.task
      worklog.customer = sheet.project.customer
      worklog.started_at = sheet.created_at
      worklog.duration = ((Time.now.utc - sheet.created_at) / 60).to_i
      worklog.body = sheet.body
      worklog.log_type = WorkLog::TASK_WORK_ADDED
      if worklog.save
        sheet.destroy
        session[:sheet] = nil
        flash['notice'] = _("Log entry saved...")
        Juggernaut.send( "do_update(#{session[:user].id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @old_task.id)}');", ["tasks_#{session[:user].company_id}"])
        Juggernaut.send( "do_update(#{session[:user].id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{session[:user].company_id}"])
      else
        flash['notice'] = _("Unable to save log entry...")
        redirect_from_last
      end
    end
  end

  def stop_work
    if session[:sheet] && sheet = Sheet.find(:first, :conditions => ["user_id = ? AND task_id = ?", session[:user].id, session[:sheet].task.id])
      worklog = WorkLog.new
      worklog.user = session[:user]
      worklog.company = session[:user].company
      worklog.project = sheet.project
      worklog.task = sheet.task
      worklog.customer = sheet.project.customer
      worklog.started_at = sheet.created_at
      worklog.duration = ((Time.now.utc - sheet.created_at) / 60).to_i
      worklog.body = sheet.body
      worklog.log_type = WorkLog::TASK_WORK_ADDED

      if worklog.save
        worklog.task.updated_by_id = session[:user].id
        worklog.task.save

        sheet.destroy
        session[:sheet] = nil
        flash['notice'] = _("Log entry saved...")
        @log = worklog
        @log.started_at = tz.utc_to_local(@log.started_at)
        @task = @log.task
        render_action 'edit_log'
      else
        flash['notice'] = _("Unable to save log entry...")
        redirect_from_last
      end
    else
      session[:sheet] = nil
      flash['notice'] = _("Log entry already saved from another browser instance.")
      redirect_from_last
    end

  end

  def update_sheet_info
  end

  def update_tasks
    @task = Task.find( params[:id], :conditions => ["company_id = ?", session[:user].company_id] )
    ActiveRecord::Base.connection.execute("update users set last_seen_at = '#{Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")}' where id = #{session[:user].id}")
  end

  def filter

    f = params[:filter]

    if f == "0"
      session[:filter_customer] = "0"
      session[:filter_milestone] = "0"
      session[:filter_project] = "0"
    elsif f[0..0] == 'c'
      session[:filter_customer] = f[1..-1]
      session[:filter_milestone] = "0"
      session[:filter_project] = "0"
    elsif f[0..0] == 'p'
      session[:filter_customer] = "0"
      session[:filter_milestone] = "0"
      session[:filter_project] = f[1..-1]
    elsif f[0..0] == 'm'
      session[:filter_customer] = "0"
      session[:filter_milestone] = f[1..-1]
      session[:filter_project] = "0"
    elsif f[0..0] == 'u'
      session[:filter_customer] = "0"
      session[:filter_milestone] = "-1"
      session[:filter_project] = f[1..-1]
    end



    session[:filter_user] = params[:filter_user]
    session[:filter_hidden] = params[:filter_hidden]
    session[:filter_status] = params[:filter_status]

    session[:group_tags] = params[:group_tags]
    session[:hide_dependencies] = params[:hide_dependencies]

    session[:user].last_filter = session[:filter_hidden]
    session[:user].last_milestone_id = session[:filter_milestone]
    session[:user].last_project_id = session[:filter_project]
    session[:user].save

    redirect_to :controller => 'tasks', :action => 'list'


  end

  def edit_log
    @log = WorkLog.find( params[:id], :conditions => ["company_id = ?", session[:user].company_id] )
    @log.started_at = tz.utc_to_local(@log.started_at)
    @task = @log.task
    render :action => 'edit_log'
  end

  def destroy_log
    @log = WorkLog.find( params[:id], :conditions => ["company_id = ?", session[:user].company_id] )
    @log.destroy
    flash['notice'] = _("Log entry deleted...")
    redirect_from_last
  end

  def add_log
    @log = Worklog.new
    @log.started_at = tz.utc_to_local(Time.now.utc)
    @log.task = Task.find(params[:id], :conditions => ["company_id = ?", session[:user].company_id])
    render :action => 'edit_log'
  end

  def save_log
    @log = WorkLog.find( params[:id], :conditions => ["company_id = ?", session[:user].company_id] )
    if @log.update_attributes(params[:log])

      if !params[:log].nil? && !params[:log][:started_at].nil? && params[:log][:started_at].length > 0
        due_date = DateTime.strptime( params[:log][:started_at], "#{session[:user].date_format} #{session[:user].time_format}" )
        @log.started_at = tz.local_to_utc(due_date)
      end
      @log.started_at = Time.now.utc if(@log.started_at.nil? || (params[:log] && (params[:log][:started_at].nil? || params[:log][:started_at].empty?)) )

      @log.duration = parse_time(params[:log][:duration], true)

      @log.task.updated_by_id = session[:user].id

      if params[:task] && params[:task][:status].to_i != @log.task.status
        @log.task.status = params[:task][:status].to_i
        @log.log_type = WorkLog::TASK_COMPLETED if params[:task][:status].to_i > 1
        @log.log_type = WorkLog::TASK_WORK_ADDED if params[:task][:status].to_i < 2
        @log.task.updated_by_id = session[:user].id
        @log.task.completed_at = Time.now.utc
        if session[:user].send_notifications > 0
            Notifications::deliver_completed( @log.task, session[:user], params[:log][:body] ) rescue begin end
        end
      end

      @log.task.save
      @log.save

      flash['notice'] = _("Log entry saved...")
      Juggernaut.send( "do_update(#{session[:user].id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @log.task.id)}');", ["tasks_#{session[:user].company_id}"])
      Juggernaut.send( "do_update(#{session[:user].id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{session[:user].company_id}"])

    end
    redirect_from_last
  end


end
