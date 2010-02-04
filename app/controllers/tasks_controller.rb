if RUBY_VERSION < "1.9"
  require "fastercsv"
else
  require "csv"
end

# Handle tasks for a Company / User
#
class TasksController < ApplicationController

  def new
    init_attributes_for_new_template

    if @projects.nil? || @projects.empty?
      flash['notice'] = _("You need to create a project to hold your tasks, or get access to create tasks in an existing project...")
      redirect_to :controller => 'projects', :action => 'new'
      return
    end
    #FIXME: Task.new instead of Task.new(params[:task])
    # action new must be accepted only via get, so params[:task] not exist
    # params[:task] exist in create and update actions
    @task = Task.new(params[:task])
    @task.company = current_user.company
    @task.duration = 0
    @task.users << current_user
  end

  def index
    redirect_to 'list'
  end

  def list
    list_init

    respond_to do |format|
      format.html { render :action => "tasks/grid" }
      format.xml  { render :action => "tasks/list.xml" }
    end
  end

  def calendar
    list_init
    respond_to do |format|
      format.html
      format.json
    end
  end

  def gantt
    list_init
  end

  # Return a json formatted list of options to refresh the Milestone dropdown
  def get_milestones
    if params[:project_id].blank?
      render :text => "" and return
    end

    @milestones = Milestone.find(:all, :order => 'milestones.due_at, milestones.name', :conditions => ['company_id = ? AND project_id = ? AND completed_at IS NULL', current_user.company_id, params[:project_id]])
    @milestones = @milestones.map { |m| { :text => m.name.gsub(/"/,'\"'), :value => m.id.to_s  } }
    @milestones = @milestones.map { |m| m.to_json }
    @milestones = @milestones.join(", ")

    res = '{"options":[{"value":"0", "text":"' + _('[None]') + '"}'
    res << ", #{@milestones}" unless @milestones.nil? || @milestones.empty?
    res << '],'
    p = current_user.projects.find(params[:project_id]) rescue nil
    if p && current_user.can?(p, 'milestone')
      res << '"add_milestone_visible":"true"'
    else
      res << '"add_milestone_visible":"false"'
    end
    res << '}'

    render :text => "#{res}"
  end

  def dependency_targets
    value = params[:dependencies][0]
    value.gsub!(/#/, '')

    @keys = [ value ]
    @tasks = Task.search(current_user, @keys)
    render :layout => false
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
    task_num = params[:dependency_id]
    conditions = { :task_num => task_num, :project_id => current_projects }
    dependency = current_user.company.tasks.find(:first, :conditions => conditions)

    render(:partial => "dependency",
           :locals => { :dependency => dependency, :perms => {} })
  end

  def create

    tags = params[:task][:set_tags]
    params[:task][:set_tags] = nil

    @task = current_user.company.tasks.new
    @task.attributes = params[:task]

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
      init_attributes_for_new_template
      render :action => 'new'
      return
    end
    #TODO: clean up this code, maybe task should accept attributes for work_log
    if @task.save && ( @task.build_work_log(params, current_user) ? @task.save : true )

      session[:last_project_id] = @task.project_id
      session[:last_task_id] = @task.id

      @task.set_users(params)
      @task.set_dependency_attributes(params[:dependencies], current_project_ids)
      @task.set_resource_attributes(params[:resource])

      create_attachments(@task)
      worklog = WorkLog.create_for_task(@task, current_user, params[:comment])

      worklog.setup_notifications(params[:notify]) do |recipients|
        Notifications::deliver_created(@task, current_user, recipients, params[:comment])
      end

      Juggernaut.send("do_update(#{current_user.id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{current_user.company_id}"])

      flash['notice'] ||= "#{ link_to_task(@task) } - #{_('Task was successfully created.')}"

      return if request.xhr?
      redirect_from_last
    else
      init_attributes_for_new_template
      return if request.xhr?
      render :action => 'new'
    end
  end

  def view
      redirect_to :action => 'edit', :id => params[:id]
  end

  def edit
    @task = current_user.company.tasks.find_by_task_num(params[:id])

    @ajax_task_links = request.xhr? # want to use ajax task loads if this page was loaded by ajax


    if @task.nil? or !current_user.can_view_task?(@task)
      flash['notice'] = _("You don't have access to that task, or it doesn't exist.")
      redirect_from_last
      return
    end

    init_form_variables(@task)
    session[:last_task_id] = @task.id
    @task.set_task_read(current_user)

    respond_to do |format|
      format.html
      format.js { render(:layout => false) }
    end
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
    projects = current_user.project_ids

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

    @task.attributes = params[:task]
    @task.build_work_log(params, current_user)

    if @task.save
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

      @task.set_users(params)
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

      assigned_ids = (params[:assigned] || [])
      assigned_ids = assigned_ids.uniq.collect { |u| u.to_i }.sort.join(',')
      if old_users != assigned_ids
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
        worklog.save!

        if params[:comment] and !params[:comment].blank?
          worklog.setup_notifications(params[:notify]) do |recipients|
            Notifications::deliver_changed(update_type, @task, current_user, recipients,
                                           email_body.gsub(/<[^>]*>/,''))
          end
        end
      end

      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])
      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{current_user.company_id}"])

      return if request.xhr?

      flash['notice'] ||= "#{ link_to_task(@task) } - #{_('Task was successfully updated.')}"
      redirect_to "/tasks/list"
    else
      init_form_variables(@task)
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
      worklog.log_type = EventLog::TASK_RESTORED
      worklog.body = ""
      worklog.save
    end
    render :nothing => true
  end


  def ajax_check
    begin
      @task = Task.find(params[:id], :conditions => ["project_id IN (?)", current_user.project_ids], :include => :project)
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
    @task = Task.find(params[:id], :conditions => ["project_id IN (?)", current_user.project_ids ], :include => :project)

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

  def get_csv
    list_init
    filename = "clockingit_tasks.csv"
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
    task = current_user.company.tasks.find_by_task_num(params[:id])
    user = current_user
    user = current_user.company.users.find(params[:user_id]) if !params[:user_id].blank?

    if task and user.can_view_task?(task)
      read = params[:read] != "false"
      task.set_task_read(user, read)
    end

    render :text => "", :layout => false
  end

  def add_notification
    @task = current_user.company.tasks.new
    if !params[:id].blank?
      @task = current_user.company.tasks.find(params[:id])
    end

    user = current_user.company.users.find(params[:user_id])
    @task.notifications.build(:user => user)

    render(:partial => "notification", :locals => { :notification => user })
  end

  def add_client
    @task = current_user.company.tasks.new
    if !params[:id].blank?
      @task = current_user.company.tasks.find(params[:id])
    end

    customer = current_user.company.customers.find(params[:client_id])
    @task.task_customers.build(:customer => customer)

    render(:partial => "task_customer", :locals => { :task_customer => customer })
  end

  def add_users_for_client
   @task = current_user.company.tasks.new
    if params[:id].present?
      @task = current_user.company.tasks.find(params[:id])
    end

    if params[:client_id].present?
      customer = current_user.company.customers.find(params[:client_id])
    elsif params[:project_id].present?
      project = current_user.projects.find_by_id(params[:project_id])
      customer = project.customer if project
    end

    users = customer ? customer.users.auto_add.all : []

    res = ""
    users.each do |user|
      res += render_to_string(:partial => "notification", :object => user)
    end

    render :text => res
  end

  def add_client_for_project
    project = current_user.projects.find(params[:project_id])
    res = ""

    if project
      res = render_to_string(:partial => "task_customer",
                             :object => project.customer)
    end

    render :text => res
  end

  def update_work_log
    log = current_user.company.work_logs.find(params[:id])
    updated = log.update_attributes(params[:work_log])

    render :text => updated.to_s
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
      unassigned = _("Unassigned")

      # only get users in currently shown tasks
      users = tasks.inject([]) { |array, task| array += task.users }
      users = users.uniq.sort_by { |u| u.name }

      users.each { |u| group_ids[u.name] = u.id }
      group_ids[unassigned] = 0
      items = [ unassigned ] + users.map { |u| u.name }

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
  ###
  # Sets up the attributes needed to display new action
  ###
  def init_attributes_for_new_template
    @projects = current_user.projects.find(:all, :order => 'name', :conditions => ["completed_at IS NULL"]).collect {  |c|
      [ "#{c.name} / #{c.customer.name}", c.id ] if current_user.can?(c, 'create')
    }.compact unless current_user.projects.nil?
      @tags = Tag.top_counts(current_user.company)
      @notify_targets = current_projects.collect{ |p| p.users.collect(&:name) }.flatten.uniq
      @notify_targets += Task.find(:all, :conditions => ["project_id IN (#{current_project_ids}) AND notify_emails IS NOT NULL and notify_emails <> ''"]).collect{ |t| t.notify_emails.split(',').collect{ |i| i.strip } }
      @notify_targets = @notify_targets.flatten.uniq
      @notify_targets ||= []
  end

  ###
  # Sets up the global variables needed to display the _form partial.
  ###
  def init_form_variables(task)
    task.due_at = tz.utc_to_local(@task.due_at) unless task.due_at.nil?
    @tags = {}

    @projects = User.find(current_user.id).projects.find(:all, :order => 'name', :conditions => ["completed_at IS NULL"]).collect {|c| [ "#{c.name} / #{c.customer.name}", c.id ] if current_user.can?(c, 'create')  }.compact unless current_user.projects.nil?

    @notify_targets = current_projects.collect{ |p| p.users.collect(&:name) }.flatten.uniq
    @notify_targets += Task.find(:all, :conditions => ["project_id IN (#{current_project_ids}) AND notify_emails IS NOT NULL and notify_emails <> ''"]).collect{ |t| t.notify_emails.split(',').collect{ |i| i.strip } }.flatten.uniq
  end

  # setup some instance variables for task list views
  def list_init
    # Subscribe to the juggernaut channel for Task updates
    session[:channels] += ["tasks_#{current_user.company_id}"]
    # @tasks = current_task_filter.tasks
    @ajax_task_links = true
  end

end
