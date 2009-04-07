# Handle tasks for a Company / User
# Author:: Erlend Simonsen (mailto:admin@clockingit.com)
#
class TasksController < ApplicationController

#  cache_sweeper :cache_sweeper, :only => [:create, :update, :destroy, :ajax_hide, :ajax_restore,
#    :ajax_check, :ajax_uncheck, :start_work_ajax, :stop_work, :swap_work_ajax, :save_log, :update_log,
#    :cancel_work_ajax, :destroy_log ]

  require_dependency 'fastercsv'

  def new
    @projects = current_user.projects.find(:all, :order => 'name', :conditions => ["completed_at IS NULL"]).collect {|c| [ "#{c.name} / #{c.customer.name}", c.id ] if current_user.can?(c, 'create')  }.compact unless current_user.projects.nil?
 
    tf = TaskFilter.new(self, @session)
    project_ids = @projects.map { |p| p[1] }

    if !project_ids.include?(tf.project_ids.first)
      session[:last_project_id] = nil
    end

    if !project_ids.include?(tf.project_ids.first)
      session[:filter_project] = nil
    end
    
    if @projects.nil? || @projects.empty?
      flash['notice'] = _("You need to create a project to hold your tasks, or get access to create tasks in an existing project...")
      redirect_to :controller => 'projects', :action => 'new'
      return
    else
      @task = Task.new
      @task.company = current_user.company
      @task.duration = 0
      @tags = Tag.top_counts({ :company_id => current_user.company_id, :project_ids => current_project_ids, :filter_hidden => session[:filter_hidden]})
      @task.watchers << current_user
    end

    @notify_targets = current_projects.collect{ |p| p.users.collect(&:name) }.flatten.uniq
    @notify_targets += Task.find(:all, :conditions => ["project_id IN (#{current_project_ids}) AND notify_emails IS NOT NULL and notify_emails <> ''"]).collect{ |t| t.notify_emails.split(',').collect{ |i| i.strip } }
    @notify_targets = @notify_targets.flatten.uniq
    @notify_targets ||= []
  end

  def index
    redirect_to 'list'
  end
  
  def list
    # Subscribe to the juggernaut channel for Task updates
    session[:channels] += ["tasks_#{current_user.company_id}"]

    @tags = {}
    @tags.default = 0
    @tags_total = 0
    project_ids = TaskFilter.filter_ids(session, :filter_project)

    if project_ids.include?(0) or project_ids.empty?
      project_ids = current_project_ids
    else
      project_ids = session[:filter_project]
    end

    task_filter = TaskFilter.new(self, params)
    @selected_tags = task_filter.selected_tags || []
    @tasks = task_filter.tasks

    # Most popular tags, currently unlimited.
    @all_tags = Tag.top_counts({ :company_id => current_user.company_id, :project_ids => project_ids, :filter_hidden => session[:filter_hidden], :filter_customer => session[:filter_customer]})
    @group_ids, @groups = group_tasks(@tasks)
  end

  # Return a json formatted list of options to refresh the Milestone dropdown
  def get_milestones
    @milestones = Milestone.find(:all, :order => 'milestones.due_at, milestones.name', :conditions => ['company_id = ? AND project_id = ? AND completed_at IS NULL', current_user.company_id, params[:project_id]]).collect{|m| "{\"text\":\"#{m.name.gsub(/"/,'\"')}\", \"value\":\"#{m.id}\"}" }.join(',')

    # {"options":[{"value":"1","text":"Test Page"}]}
    res = '{"options":[{"value":"0", "text":"' + _('[None]') + '"}'
    res << ", #{@milestones}" unless @milestones.nil? || @milestones.empty?
    res << ']}'
  
    p = current_user.projects.find(params[:project_id]) rescue nil
    script = ""
    if p && current_user.can?(p, 'milestone')
      script = "\n<script type=\"text/javascript\">if($('add_milestone')){$('add_milestone').show();}</script>"
    else 
      script = "\n<script type=\"text/javascript\">if($('add_milestone')){$('add_milestone').hide();}</script>"
    end 
    render :text => "#{res}#{script}"
  end

  def dependency_targets
    value = params[:dependencies][0]
    value.gsub!(/#/, '')

    query = ""
    @keys = value.split(' ')
    @keys.each do |k|
      query << "+issue_name:#{k}* "
    end

    # Append project id's the user has access to
    projects = "0"
    current_projects.each do |p|
      projects << "|#{p.id}"
    end
    projects = "+project_id:\"#{projects}\"" 

    # Find the tasks
    @tasks = Task.find_by_contents("+company_id:#{current_user.company_id} #{projects} #{query}", {:limit => 13})
    render :text => "<ul>#{@tasks.collect{ |t| "<li>[#{ "<strike>" if t.done? }#<span class=\"complete_value\">#{ t.task_num}</span>#{ "</strike>" if t.done? }] #{@keys.nil? ? t.name : highlight_all(t.name, @keys)}</li>"}.join("") }</ul>"
  end

  def auto_complete_for_resource_name
    return if !current_user.use_resources?

    search = params[:resource]
    search = search[:name] if search
    search = search.split(",").last if search
    @resources = []

    if !search.blank?
      conds = "lower(name) like ?"
      cond_params = [ "%#{ search.downcase }%" ]
      if params[:customer_id]
        conds += "and (customer_id is null or customer_id = ?)"
        cond_params << params[:customer_id]
      end

      conds = [ conds ] + cond_params
      @resources = current_user.company.resources.find(:all, 
                                                       :conditions => conds)
    end
  end

  def resource
    resource = current_user.company.resources.find(params[:resource_id])
    render(:partial => "resource", :locals => { :resource => resource })
  end

  def dependency
    id = params[:dependency_id]
    conditions = { :project_id => current_projects }
    dependency = current_user.company.tasks.find(id, :conditions => conditions)

    render(:partial => "dependency", 
           :locals => { :dependency => dependency, :perms => {} })
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

    render :text => "#{res}\n<script type=\"text/javascript\">resource = '<select name=\"users[]\" id=\"task_users\">#{@resource_string}</select>';</script>"
  end

#  def get_watchers
#
#    @users = Project.find(params[:project_id]).users.find(:all, :order => 'name' )
#
#    @options = @users.collect{ |u| (' {"text":"' + u.name.gsub(/"/,'\"') + '", "value":"' + u.id.to_s + '"}') }.join( ',' )
#    res = '{"options":['
#    res << "#{@options}" unless @options.nil? || @options.empty?
#    res << ']}'
#
#    render :text => "#{res}"
#  end


  def create

    tags = params[:task][:set_tags]
    params[:task][:set_tags] = nil

    @task = current_user.company.tasks.new(params[:task])

    if !params[:task].nil? && !params[:task][:due_at].nil? && params[:task][:due_at].length > 0

      repeat = @task.parse_repeat(params[:task][:due_at])
      if repeat && repeat != ""
        @task.repeat = repeat
        @task.due_at = tz.local_to_utc(@task.next_repeat_date)
      else
        @task.repeat = nil
        due_date = DateTime.strptime( params[:task][:due_at], current_user.date_format ) rescue begin
                                                                                                    flash['notice'] = _('Invalid due date ignored.')
                                                                                                    due_date = nil
                                                                                                  end
        @task.due_at = tz.local_to_utc(due_date.to_time + 1.day - 1.minute) unless due_date.nil?
      end
    else
      @task.repeat = nil
    end

    @task.company_id = current_user.company_id
    @task.updated_by_id = current_user.id
    @task.creator_id = current_user.id
    @task.duration = parse_time(params[:task][:duration], true) 
    @task.set_tags(tags) 
    @task.set_task_num(current_user.company_id)
    @task.duration = 0 if @task.duration.nil?

    unless current_user.can?(@task.project, 'create')
      flash['notice'] = _("You don't have access to create tasks on this project.")
      return if request.xhr?

      @projects = current_user.projects.find(:all, :order => 'name', :conditions => ["completed_at IS NULL"]).collect {|c| [ "#{c.name} / #{c.customer.name}", c.id ] if current_user.can?(c, 'create')  }.compact unless current_user.projects.nil?
      @tags = Tag.top_counts({ :company_id => current_user.company_id, :project_ids => current_project_ids, :filter_hidden => session[:filter_hidden]})
      @notify_targets = current_projects.collect{ |p| p.users.collect(&:name) }.flatten.uniq
      @notify_targets += Task.find(:all, :conditions => ["project_id IN (#{current_project_ids}) AND notify_emails IS NOT NULL and notify_emails <> ''"]).collect{ |t| t.notify_emails.split(',').collect{ |i| i.strip } }
      @notify_targets = @notify_targets.flatten.uniq
      @notify_targets ||= []

      render :action => 'new'
      return
    end
    
    if @task.save
      session[:last_project_id] = @task.project_id

      @task.set_watcher_attributes(params[:watchers], current_user)
      @task.set_owner_attributes(params[:users])
      @task.set_dependency_attributes(params[:dependencies], current_project_ids)
      @task.set_resource_attributes(params[:resource])

      create_attachments(@task)
      worklog = WorkLog.create_for_task(@task, current_user, params[:comment])

      if params['notify'].to_i == 1
        begin
          Notifications::deliver_created(@task, current_user, params[:comment])
        rescue
          # TODO: (from BW) why is this here? 
          # If deliver_created throws an exception don't we want to know about it?
        end
      end

      Juggernaut.send("do_update(#{current_user.id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{current_user.company_id}"])

      flash['notice'] ||= "#{link_to_task(@task)} - #{_('Task was successfully created.')}"

      return if request.xhr?
      redirect_from_last
    else
      @projects = current_user.projects.find(:all, :order => 'name', :conditions => ["completed_at IS NULL"]).collect {|c| [ "#{c.name} / #{c.customer.name}", c.id ] if current_user.can?(c, 'create')  }.compact unless current_user.projects.nil?
      @tags = Tag.top_counts({ :company_id => current_user.company_id, :project_ids => current_project_ids, :filter_hidden => session[:filter_hidden]})
      @notify_targets = current_projects.collect{ |p| p.users.collect(&:name) }.flatten.uniq
      @notify_targets += Task.find(:all, :conditions => ["project_id IN (#{current_project_ids}) AND notify_emails IS NOT NULL and notify_emails <> ''"]).collect{ |t| t.notify_emails.split(',').collect{ |i| i.strip } }
      @notify_targets = @notify_targets.flatten.uniq
      @notify_targets ||= []
      return if request.xhr?
      render :action => 'new'
    end
  end

  def view
    @task = Task.find(:first, :conditions => ["project_id IN (#{current_project_ids}) AND task_num = ?", params[:id]])
    if @task
      redirect_to :action => 'edit', :id => @task.id
    else
      redirect_to :controller => 'views', :action => 'browse'
    end
  end

  def edit
    @task = Task.find(params[:id], :conditions => ["project_id IN (?)", current_user.projects.collect{|p|p.id}] ) rescue begin
                                                                                                                           flash['notice'] = _("You don't have access to that task, or it doesn't exist.")
                                                                                                                           redirect_from_last
                                                                                                                           return
                                                                                                                         end 
                                                                                                                           
    
    
    @task.due_at = tz.utc_to_local(@task.due_at) unless @task.due_at.nil?
    @tags = Tag.top_counts({ :company_id => current_user.company_id, :project_ids => current_project_ids, :filter_hidden => session[:filter_hidden]})
    unless @logs = WorkLog.find(:all, :order => "work_logs.started_at desc,work_logs.id desc", :conditions => ["work_logs.task_id = ? #{"AND (work_logs.comment = 1 OR work_logs.log_type=6)" if session[:only_comments].to_i == 1}", @task.id], :include => [:user, :task, :project])
          @logs = []
    end
    @projects = User.find(current_user.id).projects.find(:all, :order => 'name', :conditions => ["completed_at IS NULL"]).collect {|c| [ "#{c.name} / #{c.customer.name}", c.id ] if current_user.can?(c, 'create')  }.compact unless current_user.projects.nil?

    @notify_targets = current_projects.collect{ |p| p.users.collect(&:name) }.flatten.uniq
    @notify_targets += Task.find(:all, :conditions => ["project_id IN (#{current_project_ids}) AND notify_emails IS NOT NULL and notify_emails <> ''"]).collect{ |t| t.notify_emails.split(',').collect{ |i| i.strip } }.flatten.uniq
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
    @repeat.set_tags(task.tags.collect{|t| t.name}.join(', '))
    @repeat.set_task_num(current_user.company_id)
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
    projects = current_user.projects.collect{|p|p.id}

    update_type = :updated

    @task = Task.find(params[:id], :conditions => ["project_id IN (?)", projects], :include => [:tags])
    old_tags = @task.tags.collect {|t| t.name}.sort.join(', ')
    old_deps = @task.dependencies.collect { |t| "[#{t.issue_num}] #{t.name}" }.sort.join(', ')
    old_users = @task.users.collect{ |u| u.id}.sort.join(',')
    old_users ||= "0"
    old_project_id = @task.project_id
    old_project_name = @task.project.name
    @old_task = @task.clone

    if params[:task][:status].to_i == 6
      params[:task][:status] = @task.status  # We're hiding the task, set the status to what is was.
    else
      params[:task][:hide_until] = @task.hide_until
    end

    if @task.update_attributes(params[:task])

      @task.hide_until = nil if params[:task][:hide_until].nil?

      if !params[:task].nil? && !params[:task][:due_at].nil? && params[:task][:due_at].length > 0

        repeat = @task.parse_repeat(params[:task][:due_at])
        if repeat && repeat != ""
          @task.repeat = repeat
          @task.due_at = tz.local_to_utc(@task.next_repeat_date)
        else
          @task.repeat = nil
          due_date = DateTime.strptime( params[:task][:due_at], current_user.date_format ) rescue begin
                                                                                                      flash['notice'] = _('Invalid due date ignored.')
                                                                                                      due_date = nil
                                                                                                    end
          @task.due_at = tz.local_to_utc(due_date.to_time + 1.day - 1.minute) unless due_date.nil?
        end
      else
        @task.repeat = nil
      end

      @task.set_watcher_attributes(params[:watchers], current_user)
      @task.set_owner_attributes(params[:users])
      @task.set_dependency_attributes(params[:dependencies], current_project_ids)
      @task.set_resource_attributes(params[:resource])

      @task.duration = parse_time(params[:task][:duration], true) if (params[:task] && params[:task][:duration])
      @task.updated_by_id = current_user.id

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

      @task.scheduled_duration = @task.duration if @task.scheduled? && @task.duration != @old_task.duration
      @task.scheduled_at = @task.due_at if @task.scheduled? && @task.due_at != @old_task.due_at

      @task.save

      @task.reload

      body = ""
      if @old_task[:name] != @task[:name]
        body << "- <strong>Name</strong>: #{@old_task[:name]} -> #{@task[:name]}\n"
      end

      if(@old_task.description != @task.description)
        body << "- <strong>Description</strong> changed\n"
      end

      if params[:users] && old_users != params[:users].uniq.collect{|u| u.to_i}.sort.join(',')
        logger.info("#{old_users} != #{params[:users].collect{|u| u.to_i}.sort.join(',')}")
        @task.users.reload
        new_name = @task.users.empty? ? 'Unassigned' : @task.users.collect{ |u| u.name}.join(', ')
        body << "- <strong>Assignment</strong>: #{new_name}\n"
        update_type = :reassigned
      end

      if old_project_id != @task.project_id
        body << "- <strong>Project</strong>: #{old_project_name} -> #{@task.project.name}\n"
        WorkLog.update_all("customer_id = #{@task.project.customer_id}, project_id = #{@task.project_id}", "task_id = #{@task.id}")
        ProjectFile.update_all("customer_id = #{@task.project.customer_id}, project_id = #{@task.project_id}", "task_id = #{@task.id}")
      end

      if @old_task.duration != @task.duration
        body << "- <strong>Estimate</strong>: #{worked_nice(@old_task.duration).strip} -> #{worked_nice(@task.duration)}\n"
      end

      if @old_task.milestone != @task.milestone
        old_name = "None"
        unless @old_task.milestone.nil?
           old_name = @old_task.milestone.name
           @old_task.milestone.update_counts
        end

        new_name = "None"
        new_name = @task.milestone.name unless @task.milestone.nil?

        body << "- <strong>Milestone</strong>: #{old_name} -> #{new_name}\n"
      end

      if @old_task.due_at != @task.due_at
        old_name = "None"
        old_name = current_user.tz.utc_to_local(@old_task.due_at).strftime_localized("%A, %d %B %Y") unless @old_task.due_at.nil?

        new_name = "None"
        new_name = current_user.tz.utc_to_local(@task.due_at).strftime_localized("%A, %d %B %Y") unless @task.due_at.nil?

        body << "- <strong>Due</strong>: #{old_name} -> #{new_name}\n"
      end

      new_tags = @task.tags.collect {|t| t.name}.sort.join(', ')
      if old_tags != new_tags
        body << "- <strong>Tags</strong>: #{new_tags}\n"
      end

      new_deps = @task.dependencies.collect { |t| "[#{t.issue_num}] #{t.name}"}.sort.join(", ")
      if old_deps != new_deps
        body << "- <strong>Dependencies</strong>: #{(new_deps.length > 0) ? new_deps : _("None")}"
      end

      worklog = WorkLog.new
      worklog.log_type = EventLog::TASK_MODIFIED


      if @old_task.status != @task.status
        body << "- <strong>Status</strong>: #{@old_task.status_type} -> #{@task.status_type}\n"

        worklog.log_type = EventLog::TASK_COMPLETED if @task.status > 1
        worklog.log_type = EventLog::TASK_REVERTED if (@task.status == 0 || (@task.status < 2 && @old_task.status > 1))

        if( @task.status > 1 && @old_task.status != @task.status )
          update_type = :status
        end

        if( @task.completed_at && @old_task.completed_at.nil?)
          update_type = :completed
        end

        if( @task.status < 2 && @old_task.status > 1 )
          update_type = :reverted
        end

        if( @old_task.status == 6 )
          @task.hide_until = nil
        end 

      end

      files = create_attachments(@task)
      files.each do |filename|
        body << "- <strong>Attached</strong>: #{filename}\n"
      end

      email_body = body

      if params[:comment] && params[:comment].length > 0
        update_type = :comment if body.length == 0
        worklog.log_type = EventLog::TASK_COMMENT if body.length == 0
        worklog.comment = true
        
        body << "\n" if body.length > 0
        email_body = body + current_user.name + ":\n"

        body << CGI::escapeHTML(params[:comment])
        email_body << params[:comment]
      end

      if body.length > 0
        worklog.user = current_user
        worklog.company = @task.project.company
        worklog.customer = @task.project.customer
        worklog.project = @task.project
        worklog.task = @task
        worklog.started_at = Time.now.utc
        worklog.duration = 0
        worklog.body = body
        worklog.save

        if(params['notify'].to_i == 1)
          Notifications::deliver_changed( update_type, @task, current_user, email_body.gsub(/<[^>]*>/,'')) rescue nil
        end
      end

      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])
      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{current_user.company_id}"])

      return if request.xhr?

      flash['notice'] ||= "#{link_to_task(@task)} - #{_('Task was successfully updated.')}"
      redirect_from_last
    else
      render :action => 'edit'
    end
  end

  def update_ajax
    self.update
  end

  def ajax_hide
    @task = Task.find(params[:id], :conditions => ["project_id IN (#{current_project_ids})"])

    unless @task.hidden == 1
      @task.hidden = 1
      @task.updated_by_id = current_user.id
      @task.save

      worklog = WorkLog.new
      worklog.user = current_user
      worklog.company = @task.project.company
      worklog.customer = @task.project.customer
      worklog.project = @task.project
      worklog.task = @task
      worklog.started_at = Time.now.utc
      worklog.duration = 0
      worklog.log_type = EventLog::TASK_ARCHIVED
      worklog.body = ""
      worklog.save
    end

    render :nothing => true
  end

  def create_attachments(task)
         filenames = []
         unless params['tmp_files'].blank? || params['tmp_files'].select{|f| f != ""}.size == 0
                 params['tmp_files'].each do |tmp_file|
                         next if tmp_file.is_a?(String)
                   filename = tmp_file.original_filename
             filename = filename.split("/").last
             filename = filename.split("\\").last
             filename = filename.gsub(/[^\w.]/, '_')
  
             task_file = ProjectFile.new()
             task_file.company = current_user.company
             task_file.customer = task.project.customer
             task_file.project = task.project
             task_file.task_id = task.id
             task_file.user_id = current_user.id
             task_file.filename = filename
             task_file.name = filename
             task_file.save
             task_file.file_size = tmp_file.size
  
             task_file.save
             task_file.reload
  
             File.umask(0)
             if !File.directory?(task_file.path)
              Dir.mkdir(task_file.path, 0777) rescue nil
             end
  
             File.open(task_file.file_path, "wb", 0777) { |f| f.write( tmp_file.read ) } rescue begin
                                                    flash['notice'] = _("Permission denied while saving file to #{task_file.file_path}.")
                                                    task_file.destroy
                                                    task_file = nil
                                                    next
                                                    end
             filenames << filename
             if task_file && filename[/\.gif|\.png|\.jpg|\.jpeg|\.tif|\.bmp|\.psd/i] && task_file.file_size > 0
               image = ImageOperations::get_image( task_file.file_path )
                                 if ImageOperations::is_image?(image)
                 task_file.file_type = ProjectFile::FILETYPE_IMG
                 task_file.mime_type = image.mime_type
                 task_file.save
                                         thumb = ImageOperations::thumbnail(image, 124)
                 f = File.new(task_file.thumbnail_path, "w", 0777)
                 f.write(thumb.to_blob)
                 f.close
               end
               image = thumb = nil
               GC.start
             end
           end
         end
         filenames
  end

  def ajax_restore
    @task = Task.find(params[:id], :conditions => ["project_id IN (#{current_project_ids})"])
    unless @task.hidden == 0
      @task.hidden = 0
      @task.updated_by_id = current_user.id
      @task.save

      worklog = WorkLog.new
      worklog.user = current_user
      worklog.company = @task.project.company
      worklog.customer = @task.project.customer
      worklog.project = @task.project
      worklog.task = @task
      worklog.started_at = Time.now.utc
      worklog.duration = 0
      worklog.log_type = 1
      worklog.log_type = EventLog::TASK_RESTORED
      worklog.body = ""
      worklog.save
    end
    render :nothing => true
  end


  def ajax_check
    begin
      @task = Task.find(params[:id], :conditions => ["project_id IN (?)", current_user.projects.collect{|p|p.id}], :include => :project)
    rescue
      render :nothing => true
      return
    end 

    old_status = @task.status_type
    
    unless @task.completed_at

      worklog = WorkLog.new
      worklog.user = current_user
      worklog.company = @task.project.company
      worklog.customer = @task.project.customer
      worklog.project = @task.project
      worklog.task = @task

      body = ""

      if @current_sheet && @current_sheet.task_id == @task.id
        worklog.started_at = @current_sheet.created_at
        worklog.duration = @current_sheet.duration
        worklog.paused_duration = @current_sheet.paused_duration
        worklog.log_type = EventLog::TASK_COMPLETED
        unless @current_sheet.body.blank?
          body = "\n#{@current_sheet.body}"
          worklog.comment = true 
        end 
      else 
        worklog.started_at = Time.now.utc
        worklog.duration = 0
        worklog.log_type = EventLog::TASK_COMPLETED
      end 

      @task.completed_at = Time.now.utc
      @task.updated_by_id = current_user.id
      @task.status = 2
      @task.save
      @task.reload

      worklog.body = "- <strong>Status</strong>: #{old_status} -> #{@task.status_type}\n" + body
      if worklog.save
        @current_sheet.destroy if @current_sheet && @current_sheet.task_id == @task.id
      end 


      if @task.next_repeat_date != nil
          repeat_task(@task)
      end

      if current_user.send_notifications?
        Notifications::deliver_changed(:completed, @task, current_user, worklog.body.gsub(/<[^>]*>/,'') ) rescue nil
      end

      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])
      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{current_user.company_id}"])
    end

  end

  def ajax_uncheck
    @task = Task.find(params[:id], :conditions => ["project_id IN (?)", current_user.projects.collect{|p|p.id}], :include => :project)

    unless @task.completed_at.nil?

      @task.completed_at = nil
      @task.status = 0
      @task.updated_by_id = current_user.id
      @task.save

      worklog = WorkLog.new
      worklog.user = current_user
      worklog.company = @task.project.company
      worklog.customer = @task.project.customer
      worklog.project = @task.project
      worklog.task = @task
      worklog.started_at = Time.now.utc
      worklog.duration = 0
      worklog.log_type = EventLog::TASK_REVERTED
      worklog.body = ""
      worklog.save

      if current_user.send_notifications?
        Notifications::deliver_changed(:reverted, @task, current_user, "" ) rescue begin end
      end

      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])
      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{current_user.company_id}"])
    end

  end


  def start_work
    if @current_sheet
      self.swap_work_ajax
    end
    
    task = Task.find(params[:id], :conditions => ["company_id = ?", current_user.company_id])
    sheet = Sheet.new

    sheet.task = task
    sheet.user = current_user
    sheet.project = task.project
    sheet.save

    task.status = 1 if task.status == 0
    task.save

    @current_sheet = sheet

    Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => task.id)}');", ["tasks_#{current_user.company_id}"])

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
    if @current_sheet 
      @task = @current_sheet.task
      @current_sheet.destroy
      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @current_sheet.task_id)}');", ["tasks_#{current_user.company_id}"])
      @current_sheet = nil
    end
    return if request.xhr?
    redirect_from_last
  end


  def swap_work_ajax
    if @current_sheet

      @old_task = @current_sheet.task

      if @old_task.nil?
        @current_sheet.destroy
        @current_sheet = nil
        redirect_from_last
      end

#      @old_task.updated_by_id = current_user.id
#      @old_task.save

      worklog = WorkLog.new
      worklog.user = current_user
      worklog.company = current_user.company
      worklog.project = @current_sheet.project
      worklog.task = @current_sheet.task
      worklog.customer = @current_sheet.project.customer
      worklog.started_at = @current_sheet.created_at
      worklog.duration = @current_sheet.duration
      worklog.paused_duration = @current_sheet.paused_duration
      worklog.body = @current_sheet.body
      worklog.comment = true if @current_sheet.body && @current_sheet.body.length > 0
      worklog.log_type = EventLog::TASK_WORK_ADDED
      if worklog.save
        @current_sheet.destroy
        flash['notice'] = _("Log entry saved...")
        Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @old_task.id)}');", ["tasks_#{current_user.company_id}"])
        Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{current_user.company_id}"])
        @current_sheet = nil
      else
        flash['notice'] = _("Unable to save log entry...")
        redirect_from_last
      end

    end
  end

  def add_work
    begin
      @task = Task.find( params['id'], :conditions => ["tasks.project_id IN (#{current_project_ids})"] )
    rescue
      flash['notice'] = _('Unable to find task belonging to you with that ID.')
      redirect_from_last
      return
    end

    @log = WorkLog.new
    @log.user = current_user
    @log.company = current_user.company
    @log.project = @task.project
    @log.task = @task
    @log.customer = @task.project.customer
    @log.started_at = tz.utc_to_local(Time.now.utc)
    @log.duration = 0
    @log.log_type = EventLog::TASK_WORK_ADDED
    
    @log.save
    Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])

    render :action => 'edit_log'
  end

  def stop_work
    if @current_sheet
      worklog = WorkLog.new
      worklog.user = current_user
      worklog.company = current_user.company
      worklog.project = @current_sheet.project
      worklog.task = @current_sheet.task
      worklog.customer = @current_sheet.project.customer
      worklog.started_at = @current_sheet.created_at
      worklog.duration = @current_sheet.duration
      worklog.paused_duration = @current_sheet.paused_duration
      worklog.body = @current_sheet.body
      worklog.log_type = EventLog::TASK_WORK_ADDED
      worklog.comment = true if @current_sheet.body && @current_sheet.body.length > 0 
      
      if worklog.save
        worklog.task.updated_by_id = current_user.id
        worklog.task.save

        @current_sheet.destroy
        flash['notice'] = _("Log entry saved...")
        @log = worklog
        @log.started_at = tz.utc_to_local(@log.started_at)
        @task = @log.task
        render :action => 'edit_log'
        Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])
      else
        flash['notice'] = _("Unable to save log entry...")
        redirect_from_last
      end
    else
      @current_sheet = nil
      flash['notice'] = _("Log entry already saved from another browser instance.")
      redirect_from_last
    end

  end

  def stop_work_shortlist
    unless @current_sheet
      render :nothing => true
      return
    end

    @task = @current_sheet.task
    swap_work_ajax
    Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])
#    redirect_to :action => 'shortlist'
  end

  def updatelog
    unless @current_sheet
      render :text => "#{_("Task not worked on")} #{current_user.tz.utc_to_local(Time.now.utc).strftime_localized("%H:%M:%S")}"
      return
    end 
    if params[:worklog] && params[:worklog][:body] 
      @current_sheet.body = params[:worklog][:body] 
      @current_sheet.save
      render :text => "#{_("Saved")} #{current_user.tz.utc_to_local(Time.now.utc).strftime_localized("%H:%M:%S")}"
    else 
      render :text => "#{_("Error saving")} #{current_user.tz.utc_to_local(Time.now.utc).strftime_localized("%H:%M:%S")}"
    end 
  end
  
  
  def update_sheet_info
  end

  def update_tasks
    @task = Task.find( params[:id], :conditions => ["company_id = ?", current_user.company_id] )
  end

  def filter_shortlist

    tmp = { }
    [:filter_customer, :filter_milestone, :filter_project, :filter_user, :filter_hidden, :filter_status, :group_by, :hide_deferred, :hide_dependencies, :sort, :filter_type, :filter_severity, :filter_priority].each do |v|
      tmp[v] = session[v]
    end

    do_filter

    session[:filter_project_short] = session[:filter_project]
    session[:filter_customer_short] = session[:filter_customer]
    session[:filter_milestone_short] = session[:filter_milestone]

    [:filter_customer, :filter_milestone, :filter_project, :filter_user, :filter_hidden, :filter_status, :group_by, :hide_deferred, :hide_dependencies, :sort, :filter_type, :filter_severity, :filter_priority].each do |v|
      session[v] = tmp[v]
    end

    redirect_to :controller => 'tasks', :action => 'shortlist'
  end

  def edit_log
    @log = WorkLog.find( params[:id], :conditions => ["company_id = ?", current_user.company_id] )
    @log.started_at = tz.utc_to_local(@log.started_at)
    @task = @log.task
  end

  def destroy_log
    @log = WorkLog.find( params[:id], :conditions => ["company_id = ?", current_user.company_id] )
    @log.destroy
    flash['notice'] = _("Log entry deleted...")
    redirect_from_last
  end

  def add_log
    @log = Worklog.new
    @log.started_at = tz.utc_to_local(Time.now.utc)
    @log.task = Task.find(params[:id], :conditions => ["company_id = ?", current_user.company_id])
    render :action => 'edit_log'
  end

  def save_log
    @log = WorkLog.find( params[:id], :conditions => ["company_id = ?", current_user.company_id] )
    
    old_duration = @log.duration
    old_note = @log.body
    
    if !params[:log].nil? && !params[:log][:started_at].nil? && params[:log][:started_at].length > 0
      begin
        due_date = DateTime.strptime( params[:log][:started_at], "#{current_user.date_format} #{current_user.time_format}" )
        params[:log][:started_at] = tz.local_to_utc(due_date)
      rescue
        params[:log][:started_at] = Time.now.utc
      end
    end

    if @log.update_attributes(params[:log])


      @log.started_at = Time.now.utc if(@log.started_at.blank? || (params[:log] && (params[:log][:started_at].blank?)) )

      @log.duration = parse_time(params[:log][:duration])
      @log.duration = old_duration if((old_duration / 60) == (@log.duration / 60)) 

      @log.task.updated_by_id = current_user.id

      @log.comment = !@log.body.blank?
      
      if params[:task] && params[:task][:status].to_i != @log.task.status

        status_type = :completed

        if params[:task][:status].to_i < 2
          @log.log_type = EventLog::TASK_WORK_ADDED 
          status_type = :updated
        end 
        
        if params[:task][:status].to_i > 1 && @log.task.status < 2
          @log.log_type = EventLog::TASK_COMPLETED 
          status_type = :completed
        end 

        if params[:task][:status].to_i < 2 && @log.task.status > 1
          @log.log_type = EventLog::TASK_REVERTED 
          status_type= :reverted
        end 
        
        @log.task.status = params[:task][:status].to_i
        @log.task.updated_by_id = current_user.id
        @log.task.completed_at = Time.now.utc
        Notifications::deliver_changed( status_type, @log.task, current_user, params[:log][:body] ) if(params['notify'].to_i == 1) rescue nil

      elsif !params[:log][:body].blank? && params[:log][:body] != old_note &&  params['notify'].to_i == 1
        Notifications::deliver_changed( :comment, @log.task, current_user, params[:log][:body].gsub(/<[^>]*>/,'')) rescue nil
      end

      @log.task.save
      @log.save

      flash['notice'] = _("Log entry saved...")
      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @log.task.id)}');", ["tasks_#{current_user.company_id}"])
      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{current_user.company_id}"])

    end
    redirect_from_last
  end

  def get_csv
    list

    filename = "clockingit_tasks"
    filename_extras = []

    tf = TaskFilter.new(self, session)
    tf.customer_ids.each do |id|
      next if id < 0
      filename_extras << current_user.company.customers.find(id).name
    end
    tf.project_ids.each do |id|
      next if id < 0
      p = current_user.projects.find(id)
      filename_extras << "#{p.customer.name}_#{p.name}"
    end
    tf.milestone_ids.each do |id|
      next if id < 0
      m = current_user.company.milestones.find(id)

      filename_extras << "#{m.project.customer.name}_#{m.project.name}_#{m.name}"
    end
    TaskFilter.filter_user_ids(session, TaskFilter::ALL_USERS).each do |id|
      next if id < 0
      filename_extras << current_user.company.users.find(id).name
    end
    TaskFilter.filter_status_ids(session).each do |id|
      value = Task.status_type(id)
      filename_extras << value if !value.blank?
    end

    filename_extras = filename_extras.join("_")
    filename += "_#{ filename_extras }" if !filename_extras.blank?

    filename = filename.gsub(/ /, "_").gsub(/["']/, '').downcase
    filename << ".csv"

    csv_string = FasterCSV.generate( :col_sep => "," ) do |csv|

      header = ['Client', 'Project', 'Num', 'Name', 'Tags', 'User', 'Milestone', 'Due', 'Created', 'Completed', 'Worked', 'Estimated', 'Status', 'Priority', 'Severity']
      csv << header

      for t in @tasks
        csv << [t.project.customer.name, t.project.name, t.task_num, t.name, t.tags.collect(&:name).join(','), t.owners, t.milestone.nil? ? nil : t.milestone.name, t.due_at.nil? ? t.milestone.nil? ? nil : t.milestone.due_at : t.due_at, t.created_at, t.completed_at, t.worked_minutes, t.duration, t.status_type, t.priority_type, t.severity_type]
      end

    end
    logger.info("Seinding[#{filename}]")

    send_data(csv_string,
              :type => 'text/csv; charset=utf-8; header=present',
              :filename => filename)
  end

  def move
    begin
      body = ""
      elems = params[:id].split(' ')
      element = elems[0].split('_')[1]

      @group = elems[1].split('_')[1].to_i

      @task = Task.find(element, :conditions => ["project_id IN (#{current_project_ids})"])

      worklog = WorkLog.new
      worklog.log_type = EventLog::TASK_MODIFIED

      update_type = :updated

      case session[:group_by].to_i
      when 3
        # Project
        project = current_user.projects.find(@group)
        if @task.project_id != project.id
          body = "- <strong>Project</strong>: #{@task.project.name} -> #{project.name}\n"
          old_milestone = nil
          if @task.milestone
            body << "- <strong>Milestone</strong>: #{@task.milestone.name} -> None"
            old_milestone = @task.milestone
            @task.milestone = nil
          end
          @task.project_id = project.id
          @task.save

          WorkLog.update_all("customer_id = #{project.customer_id}, project_id = #{@task.project_id}", "task_id = #{@task.id}")
          ProjectFile.update_all("customer_id = #{project.customer_id}, project_id = #{@task.project_id}", "task_id = #{@task.id}")

          old_milestone.update_counts if old_milestone
        end
      when 4
        # Milestone
        milestone = Milestone.find(@group, :conditions => ["project_id IN (#{current_project_ids})"]) if @group > 0

        if(@task.milestone_id.to_i) != @group
          if( milestone && milestone.project_id != @task.project_id )
            body << "- <strong>Project</strong>: #{@task.project.name} -> #{milestone.project.name}\n"
            @task.project_id = milestone.project_id
            WorkLog.update_all("customer_id = #{milestone.project.customer_id}, project_id = #{milestone.project_id}", "task_id = #{@task.id}")
            ProjectFile.update_all("customer_id = #{milestone.project.customer_id}, project_id = #{milestone.project_id}", "task_id = #{@task.id}")
          end

          if @task.milestone_id != @group
            old_milestone = @task.milestone.nil? ? "None" : @task.milestone.name
            new_milestone = milestone.nil? ? "None" : milestone.name

            body << "- <strong>Milestone</strong>: #{old_milestone} -> #{new_milestone}"

            old = @task.milestone

            @task.milestone = milestone
            @task.save

            old.update_counts if old

          end
        end
      when 5
        # User

        old_users = @task.users.collect{ |u| u.id}.sort.join(',')
        old_users = "0" if old_users.nil? || old_users.empty?

        @task.task_owners.destroy_all
        if @group > 0
          u = User.find(@group, :conditions => ["company_id = ?", current_user.company_id])
          to = TaskOwner.new(:user => u, :task => @task)
          to.save

          if( old_users != u.name )
            new_name = u.name
            body = "- <strong>Assignment</strong>: #{new_name}\n"
            @task.users.reload
            update_type = :reassigned
          end

        end
        @task.save
      when 7
        # Status
        if( @task.status != @group )
          if @group < 2
            @task.completed_at = nil
            if @task.status > 1
              worklog.log_type = EventLog::TASK_REVERTED
              update_type = :reverted
            end
          else
            @task.completed_at = Time.now.utc if @task.completed_at.nil?
            if @task.status < 2
              worklog.log_type = EventLog::TASK_COMPLETED
              update_type = :completed
            end
          end
          body << "- <strong>Status</strong>: #{@task.status_type} -> #{Task.status_types[@group]}\n"
          @task.status = @group
          @task.save
        end
      when 10
        # Project / Milestone
        # task-group_44_15

        project = current_user.projects.find(@group)
        old = @task.milestone

        if @task.project_id != @group
          body << "- <strong>Project</strong>: #{@task.project.name} -> #{project.name}\n"
          @task.project_id = @group
        end

        if elems[1].split('_').size > 2
          milestone = Milestone.find(elems[1].split('_')[2], :conditions => ["project_id IN (#{current_project_ids})"])

          
          if @task.milestone_id != milestone.id
            old_milestone = @task.milestone.nil? ? "None" : @task.milestone.name
            new_milestone = milestone.nil? ? "None" : milestone.name
            body << "- <strong>Milestone</strong>: #{old_milestone} -> #{new_milestone}"

            @task.milestone_id = milestone.id

          end
          @group = "#{@group}_#{milestone.id}"
        else
          unless @task.milestone_id.nil?
            old_milestone = @task.milestone.nil? ? "None" : @task.milestone.name
            new_milestone = "None"
            body << "- <strong>Milestone</strong>: #{old_milestone} -> #{new_milestone}"
            @task.milestone_id = nil
          end
        end

        WorkLog.update_all("customer_id = #{project.customer_id}, project_id = #{project.id}", "task_id = #{@task.id}")
        ProjectFile.update_all("customer_id = #{project.customer_id}, project_id = #{project.id}", "task_id = #{@task.id}")

        @task.save
        old.update_counts if old
      end

      if (property = Property.find_by_group_by(current_user.company, session[:group_by]))
        old_value = @task.property_value(property)
        new_value = property.property_values.find(@group) if @group.to_i > 0
        @task.set_property_value(property, new_value)
        body <<  " - <strong>#{ property }</strong>: #{ old_value } -> #{ new_value }"
      end


      if body.length > 0
        @task.reload
        worklog.user = current_user
        worklog.company = @task.project.company
        worklog.customer = @task.project.customer
        worklog.project = @task.project
        worklog.task = @task
        worklog.started_at = Time.now.utc
        worklog.duration = 0
        worklog.body = body
        worklog.save
        Notifications::deliver_changed( update_type, @task, current_user, body.gsub(/<[^>]*>/,'')) if current_user.send_notifications? rescue nil
        Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])
      end

    end

  end

  def toggle_history
    session[:only_comments] ||= 0
    session[:only_comments] = 1 - session[:only_comments]

    @task = Task.find(params[:id], :conditions => ["project_id IN (#{current_project_ids})"])
    unless @logs = WorkLog.find(:all, :order => "work_logs.started_at desc,work_logs.id desc", :conditions => ["work_logs.task_id = ? #{"AND (work_logs.comment = 1 OR work_logs.log_type=6)" if session[:only_comments].to_i == 1}", @task.id], :include => [:user, :task, :project])
      @logs = []
    end

    render :update do |page|
      page.replace_html 'task_history', :partial => 'history'
      page.visual_effect(:highlight, "task_history", :duration => 2.0)
    end
  end

  def quick_add
    self.new
    render :update do |page|
      page.replace_html 'quick_add_container', :partial => 'quick_add'
      page.show('quick_add_container')
      page.visual_effect(:highlight, "quick_add_container", :duration => 0.5)
    end
  end

  def create_ajax
    self.create
    unless @task.id
      render :update do |page|
        page.visual_effect(:highlight, "quick_add_container", :duration => 0.5, :startcolor => "#ff9999")
      end
    else
      @task.reload
      render :update do |page|
        page.insert_html :top, "task_list", :partial => 'task_row', :locals => { :task => @task, :depth => 0}
        ['task_name', 'task_set_tags', 'task_description', 'dependencies_input', 'task_duration'].each do |el|
          page.call "$('#{el}').clear"
        end
        page.visual_effect(:highlight, "task_#{@task.id}", :duration => 1.5)
        page << "$('task_name').focus();"
        page.call("updateTooltips")
      end
    end
  end

  def create_shortlist_ajax

    if !params[:task][:name] || params[:task][:name].empty?
      render :update do |page|
        page.visual_effect(:highlight, "shortlist", :duration => 0.5, :startcolor => "#ff9999")
      end
      return
    end

    @task = Task.new
    @task.name = params[:task][:name]
    @task.company_id = current_user.company_id
    @task.updated_by_id = current_user.id
    @task.creator_id = current_user.id
    @task.duration = 0
    @task.set_task_num(current_user.company_id)
    @task.description = ""

    if session[:filter_milestone_short].to_i > 0
      @task.project = Milestone.find(:first, :conditions => ["company_id = ? AND id = ?", current_user.company_id, session[:filter_milestone_short]]).project
      @task.milestone_id = session[:filter_milestone_short].to_i
    elsif session[:filter_project_short].to_i > 0
      @task.project_id = session[:filter_project_short].to_i
      @task.milestone_id = nil
    else
      render :update do |page|
        page.visual_effect(:highlight, "shortlist", :duration => 0.5, :startcolor => "#ff9999")
      end
      return
    end

    @task.save
    @task.reload

    unless @task.id
      render :update do |page|
        page.visual_effect(:highlight, "quick_add_container", :duration => 0.5, :startcolor => "#ff9999")
      end
    else
      to = TaskOwner.new(:user => current_user, :task => @task)
      to.save

      worklog = WorkLog.new
      worklog.user = current_user
      worklog.company = @task.project.company
      worklog.customer = @task.project.customer
      worklog.project = @task.project
      worklog.task = @task
      worklog.started_at = Time.now.utc
      worklog.duration = 0
      worklog.log_type = EventLog::TASK_CREATED
      worklog.body = ""
      worklog.save
      if params['notify'].to_i == 1
        Notifications::deliver_created( @task, current_user, params[:comment]) rescue begin end
      end

      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])
      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{current_user.company_id}"])

      render :update do |page|
        page.insert_html :bottom, "shortlist-tasks", :partial => 'task_row', :locals => { :task => @task, :depth => 0}
        page.visual_effect(:highlight, "task_#{@task.id}", :duration => 1.5)
        page << "$('task_name').focus();"
        page.call("fixShortLinks")
        page.call("updateTooltips")
      end
    end
  end

  def shortlist
    tmp = { }
    # Save filtering
    [:filter_customer, :filter_milestone, :filter_project, :filter_user, :filter_hidden, :filter_status, :group_by, :hide_deferred, :hide_dependencies, :sort].each do |v|
      tmp[v] = session[v]
    end

    session[:filter_project] = session[:filter_project_short] if session[:filter_project_short]
    session[:filter_customer] = session[:filter_customer_short] if session[:filter_project_short]
    session[:filter_milestone] = session[:filter_milestone_short] if session[:filter_project_short]
    session[:filter_user] = current_user.id.to_s
    session[:filter_hidden] = "0"
    session[:filter_status] = "0"
    session[:group_by] = "0"
    session[:hide_deferred] = "1"
    session[:hide_dependencies] = "1"
    session[:sort] = "0"

    self.list

    # Restore filtering
    [:filter_customer, :filter_milestone, :filter_project, :filter_user, :filter_hidden, :filter_status, :group_by, :hide_deferred, :hide_dependencies, :sort].each do |v|
      session[v] = tmp[v]
    end

    render :layout => 'shortlist'
  end

  def pause_work_ajax
    if @current_sheet 
      if @current_sheet.paused_at
        @current_sheet.paused_duration += (Time.now.utc - @current_sheet.paused_at).to_i
        @current_sheet.paused_at = nil
      else
        @current_sheet.paused_at = Time.now.utc
      end
      @current_sheet.save
    else 
      render :nothing => true
      Juggernaut.send( "do_update(0, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => params[:id])}');", ["tasks_#{current_user.company_id}"])
      return
    end
  end


  def create_todo_ajax

    if params[:todo][:name].blank?
      render :update do |page|
        page.visual_effect(:highlight, "todo-form-#{params[:id]}", :duration => 0.5, :startcolor => "#ff9999")
      end
      return
    end

    @task = Task.find(:first, :conditions => ["id = ? AND project_id IN (#{current_project_ids})", params[:id]])
    unless @task
      render :update do |page|
        page.visual_effect(:highlight, "todo-form-#{params[:id]}", :duration => 0.5, :startcolor => "#ff9999")
      end
      return
    end
    @todo = Todo.new
    @todo.name = params[:todo][:name]
    @todo.creator_id = current_user.id
    @todo.task_id = @task.id

    unless @todo.save
      render :update do |page|
        page.visual_effect(:highlight, "todo-form-tasks-#{params[:id]}", :duration => 0.5, :startcolor => "#ff9999")
      end
    else
      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => params[:id])}');", ["tasks_#{current_user.company_id}"])
      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{current_user.company_id}"])

      render :update do |page|
        page.insert_html :bottom, "todo-#{@task.dom_id}", :partial => "tasks/todo_row"
        page.replace_html "todo-status-#{@task.dom_id}", link_to_function( "#{@task.todo_status}", "Element.toggle('todo-container-#{@task.dom_id}');", :class => (@task.todos.empty? ? "todo-status-link-empty" :"todo-status-link"))
        page << "$('todo_text_#{@task.id}').clear();"
        page << "$('todo_text_#{@task.id}').focus();"
        page.call("updateTooltips")
        page.visual_effect :highlight, @todo.dom_id
        page << "Sortable.create('todo-#{@task.dom_id}', {containment:'todo-#{@task.dom_id}', format:/^[^-]*-(.*)$/, onUpdate:function(){new Ajax.Request('/tasks/order_todos/#{@task.id}', {asynchronous:true, evalScripts:true, parameters:Sortable.serialize('todo-#{@task.dom_id}')})}, only:'todo-active'})"
      end
    end

  end

  def todo_edit_ajax
    if params[:id].blank?
      return
    end

    @todo = Todo.find(:first, :conditions => ["todos.id = ? AND tasks.project_id IN (#{current_project_ids})", params[:id]], :include => [:task] )
    unless @todo
      return
    end

    if params[:todo].blank? || params[:todo][:name].blank?
      render :update do |page|
        page.replace @todo.dom_id, :partial => "todo_edit_row"
        page << "$('todo_text_#{@todo.dom_id}').focus();"
      end 
    else 
      @todo.name = params[:todo][:name]
      @todo.save
      render :update do |page|
        page.replace_html @todo.dom_id, :partial => "todo_row"
        page << "Sortable.create(\"todo-#{@todo.task.dom_id}\", {containment:'todo-#{@todo.task.dom_id}', format:/^[^-]*-(.*)$/, onUpdate:function(){new Ajax.Request('/tasks/order_todos/#{@todo.task.id}', {asynchronous:true, evalScripts:true, parameters:Sortable.serialize(\"todo-#{@todo.task.dom_id}\")})}, only:'todo-active'})"
        page.call("updateTooltips")
      end 
      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @todo.task.id)}');", ["tasks_#{current_user.company_id}"])
      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{current_user.company_id}"])
    end 
  end

  def todo_edit_cancel_ajax
    if params[:id].blank?
      return
    end

    @todo = Todo.find(:first, :conditions => ["todos.id = ? AND tasks.project_id IN (#{current_project_ids})", params[:id]], :include => [:task] )
    unless @todo
      return
    end

    render :update do |page|
      page.replace @todo.dom_id, :partial => "todo_row"
      page << "Sortable.create(\"todo-#{@todo.task.dom_id}\", {containment:'todo-#{@todo.task.dom_id}', format:/^[^-]*-(.*)$/, onUpdate:function(){new Ajax.Request('/tasks/order_todos/#{@todo.task.id}', {asynchronous:true, evalScripts:true, parameters:Sortable.serialize(\"todo-#{@todo.task.dom_id}\")})}, only:'todo-active'})"
    end 

  end 

  def todo_check_ajax
    begin
      @todo = Todo.find(params[:id])
    rescue
      render :nothing => true
      return
    end
    @task = Task.find(:first, :conditions => ["id = ? AND project_id IN (#{current_project_ids})", @todo.task_id])
    unless @task
      render :update do |page|
        page.visual_effect(:highlight, "todos-#{params[:id]}", :duration => 0.5, :startcolor => "#ff9999")
      end
      return
    end

    if @todo.completed_at
      @todo.completed_at = nil
    else
      @todo.completed_by_user = current_user
      @todo.completed_at = Time.now.utc
    end
    if @todo.save
      render :update do |page|
        if @todo.completed_at
          page.remove @todo.dom_id
          page.insert_html :top, "todo-done-#{@task.dom_id}", :partial => "tasks/todo_row"
          page.replace_html "todo-status-#{@task.dom_id}", link_to_function( "#{@task.todo_status}", "Element.toggle('todo-container-#{@task.dom_id}');", :class => (@task.todos.empty? ? "todo-status-link-empty" :"todo-status-link"))
        else
          @todo.move_to_bottom
          page.remove @todo.dom_id
          page.insert_html :bottom, "todo-#{@task.dom_id}", :partial => "tasks/todo_row"
          page.replace_html "todo-status-#{@task.dom_id}", link_to_function( "#{@task.todo_status}", "Element.toggle('todo-container-#{@task.dom_id}');", :class => (@task.todos.empty? ? "todo-status-link-empty" :"todo-status-link"))
        end
        page << "Sortable.create('todo-#{@task.dom_id}', {containment:'todo-#{@task.dom_id}', format:/^[^-]*-(.*)$/, onUpdate:function(){new Ajax.Request('/tasks/order_todos/#{@task.id}', {asynchronous:true, evalScripts:true, parameters:Sortable.serialize('todo-#{@task.dom_id}')})}, only:'todo-active'})"
        page.call("updateTooltips")
        page.visual_effect(:highlight, "#{@todo.dom_id}", :duration => 1.5)
      end
      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])
      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{current_user.company_id}"])
    else
      render :update do |page|
        page.visual_effect(:highlight, "#{@todo.dom_id}", :duration => 0.5, :startcolor => "#ff9999")
      end
    end

  end

  def order_todos
    @task = Task.find(:first, :conditions => ["id = ? AND project_id IN (#{current_project_ids})", params[:id]])
    @task.todos.find(:all, :conditions => ["completed_at IS NULL"]).each do |todo|
      todo.position = params["todo-tasks-#{@task.id}"].index(todo.id.to_s) + 1
      todo.save
    end
    render :update do |page|
      page.visual_effect(:highlight, "todo-#{@task.dom_id}")
    end
    Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])
  end

  def todo_delete_ajax
    begin
      @todo = Todo.find(params[:id])
    rescue
      render :update do |page|
        page.visual_effect(:highlight, "todos-#{params[:id]}", :duration => 0.5, :startcolor => "#ff9999")
      end
      return
    end
    @task = Task.find(:first, :conditions => ["id = ? AND project_id IN (#{current_project_ids})", @todo.task_id])

    if @task
      element = @todo.dom_id
      @todo.destroy
      render :update do |page|
        page.visual_effect :fade, element
        page.replace_html "todo-status-#{@task.dom_id}", link_to_function( "#{@task.todo_status}", "Element.toggle('todo-container-#{@task.dom_id}');", :class => (@task.todos.empty? ? "todo-status-link-empty" :"todo-status-link"))
        page.delay(1.0) do
          page.remove element
        end
      end
      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])
    else
      render :update do |page|
        page.visual_effect(:highlight, "todos-#{params[:id]}", :duration => 0.5, :startcolor => "#ff9999")
      end
    end
  end

  def tags
    @tags = current_user.company.tags
  end 

  def delete_tag
    tag = current_user.company.tags.find(params[:id]) rescue nil
    if tag
      tag.destroy
      render :update do |page|
        page.remove tag.dom_id
      end 
    else 
      render :nothing => true
    end 
  end 

  def save_tag
    @tag = current_user.company.tags.find(params[:id]) rescue nil
    if @tag && !params['tag-name'].blank?
      if Tag.exists?(:company_id => current_user.company_id, :name => params['tag-name'])
        
        @existing = current_user.company.tags.find(:first, :conditions => ["name = ?", params['tag-name']] )
        if @existing.id != @tag.id
          @tag.tasks.each do |t|
            @existing.tasks << t
          end 
          @tag.destroy
          render :update do |page|
            page[@tag.dom_id].remove
            @tag = @existing
            page[@tag.dom_id].replace :partial => 'edit_tag_row'
          end 
        else
          render :update do |page|
            page[@tag.dom_id].replace :partial => 'edit_tag_row'
          end 

        end 

      else 
        @tag.name = params['tag-name']
        @tag.save
        render :update do |page|
          page[@tag.dom_id].replace :partial => 'edit_tag_row'
        end 
      end 
    else 
      render :nothing => true
    end 
  end

  def get_comment
    @task = Task.find(params[:id], :conditions => "project_id IN (#{current_project_ids})") rescue nil
    if @task
      @comment = WorkLog.find(:first, :order => "work_logs.started_at desc,work_logs.id desc", :conditions => ["work_logs.task_id = ? AND work_logs.comment = 1", @task.id], :include => [:user, :task, :project])
    end 
  end 

  ###
  # This action just sets the unread status for a task.
  ###
  def set_unread
    task = Task.find(params[:id], 
                     :conditions => "project_id IN (#{current_project_ids})")

    read = params[:read] != "false"
    task.set_task_read(current_user, read)

    render :text => "", :layout => false
  end

  private

  ###
  # Returns a two element array containing the grouped tasks.
  # The first element is an in-order array of group ids / names
  # The second element is a hash mapping group ids / names to arrays of tasks.
  ###
  def group_tasks(tasks)
    group_ids = {}
    groups = []
        
    if session[:group_by].to_i == 1 # tags
      @tag_names = @all_tags.collect{|i,j| i}
      groups = Task.tag_groups(current_user.company_id, @tag_names, tasks)
    elsif session[:group_by].to_i == 2 # Clients
      clients = Customer.find(:all, :conditions => ["company_id = ?", current_user.company_id], :order => "name")
      clients.each { |c| group_ids[c.name] = c.id }
      items = clients.collect(&:name).sort
      groups = Task.group_by(tasks, items) { |t,i| t.project.customer.name == i }
    elsif session[:group_by].to_i == 3 # Projects
      projects = current_user.projects
      projects.each { |p| group_ids[p.full_name] = p.id }
      items = projects.collect(&:full_name).sort
      groups = Task.group_by(tasks, items) { |t,i| t.project.full_name == i }

    elsif session[:group_by].to_i == 4 # Milestones
      tf = TaskFilter.new(self, session)
      
      if tf.milestone_ids.any?
        filter = " AND id in (#{ tf.milestone_ids.join(",") })"
      elsif tf.project_ids.any?
        filter = " AND project_id in (#{ tf.project_ids.join(",") })"
      elsif tf.customer_ids.any?
        projects = []
        tf.customer_ids.each { |id| projects += Customer.find(id).projects }
        projects = projects.map { |p| p.id }
        filter = " AND project_id IN (#{ projects.join(",") })"
      end

      conditions = "company_id = #{ current_user.company.id }"
      conditions += " AND project_id IN (#{current_project_ids})#{filter} "
      conditions += " AND completed_at IS NULL"

      milestones = Milestone.find(:all, :conditions => conditions, 
                                  :order => "due_at, name")
      milestones.each { |m| group_ids[m.name + " / " + m.project.name] = m.id }
      group_ids['Unassigned'] = 0
      items = ["Unassigned"] +  milestones.collect{ |m| m.name + " / " + m.project.name }
      groups = Task.group_by(tasks, items) { |t,i| (t.milestone ? (t.milestone.name + " / " + t.project.name) : "Unassigned" ) == i }

    elsif session[:group_by].to_i == 5 # Users
      users = current_user.company.users
      users.each { |u| group_ids[u.name] = u.id }
      group_ids[_('Unassigned')] = 0
      items = [_("Unassigned")] + users.collect(&:name).sort
      groups = Task.group_by(tasks, items) { |t,i|
        if t.users.size > 0
          res = t.users.collect(&:name).include? i
        else
          res = (_("Unassigned") == i)
          end
        res
      }
    elsif session[:group_by].to_i == 7 # Status
      0.upto(5) { |i| group_ids[ _(Task.status_types[i]) ] = i }
      items = Task.status_types.collect{ |i| _(i) }
      groups = Task.group_by(tasks, items) { |t,i| _(t.status_type) == i }
    elsif session[:group_by].to_i == 10 # Projects / Milestones
      milestones = Milestone.find(:all, :conditions => ["company_id = ? AND project_id IN (#{current_project_ids}) AND completed_at IS NULL", current_user.company_id], :order => "due_at, name")
      projects = current_user.projects

      milestones.each { |m| group_ids["#{m.project.name} / #{m.name}"] = "#{m.project_id}_#{m.id}" }
      projects.each { |p| group_ids["#{p.name}"] = p.id }

      items = milestones.collect{ |m| "#{m.project.name} / #{m.name}" }.flatten
      items += projects.collect(&:name)
      items = items.uniq.sort

      groups = Task.group_by(tasks, items) { |t,i| t.milestone ? ("#{t.project.name} / #{t.milestone.name}" == i) : (t.project.name == i)  }
    elsif session[:group_by].to_i == 11 # Requested By
      requested_by = tasks.collect{|t| t.requested_by.blank? ? nil : t.requested_by }.compact.uniq.sort
      requested_by = [_('No one')] + requested_by
      groups = Task.group_by(tasks, requested_by) { |t,i| (t.requested_by.blank? ? _('No one') : t.requested_by) == i }
    elsif (property = Property.find_by_group_by(current_user.company, session[:group_by]))
      items = property.property_values
      items.each { |pbv| group_ids[pbv] = pbv.id }

      # add in for tasks without values
      unassigned = _("Unassigned")
      group_ids[unassigned] = 0
      items = [ unassigned ] + items

      groups = Task.group_by(tasks, items) do |task, match_value|
        value = task.property_value(property)
        group = (value and value == match_value)
        group ||= (value.nil? and match_value == unassigned)
        group
        end
    else
      groups = [tasks]
      end


    return [ group_ids, groups ]
    end

end
