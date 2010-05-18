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
    @task = current_company_task_new
    @task.duration = 0
    @task.users << current_user
    render :template=>'tasks/new'
  end

  def index
    redirect_to 'list'
  end

  def list
    list_init

    @tasks= tasks_for_list
    respond_to do |format|
      format.html { render :action => "grid" }
      format.xml  { render :template => "tasks/list.xml" }
    end
  end

  def calendar
    list_init
    respond_to do |format|
      format.html
      format.json{
        @tasks=current_task_filter.tasks_for_fullcalendar(params)
      }
    end
  end

  def gantt
    list_init
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
    render :layout=> false
  end

  def resource
    resource = current_user.company.resources.find(params[:resource_id])
    render(:partial => "resource", :locals => { :resource => resource })
  end

  def dependency
    dependency = Task.accessed_by(current_user).find_by_task_num(params[:dependency_id])
    render(:partial => "dependency",
           :locals => { :dependency => dependency, :perms => {} })
  end

  def create

    tags = params[:task][:set_tags]
    params[:task][:set_tags] = nil

    @task = current_company_task_new
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
      render :template => 'tasks/new'
      return
    end
    #One task can have two  worklogs, so following code can raise three exceptions
    #ActiveRecord::RecordInvalid or ActiveRecord::RecordNotSaved
    begin
      ActiveRecord::Base.transaction do
        @task.save!
        create_worklogs_for_tasks_create
      end
      session[:last_project_id] = @task.project_id
      set_last_task(@task)

      @task.set_users_dependencies_resources(params, current_user)

      create_attachments(@task)

      ############ code smell begin ####################
      # this code used to create tasks from task template
      # must exist more elegancy solution
      copy_todos_from_template(params[:task][:id], @task)
      ############ code smell end #######################

      @task.work_logs.each{ |w| w.send_notifications }

      flash['notice'] ||= "#{ link_to_task(@task) } - #{_('Task was successfully created.')}"

      return if request.xhr?
      redirect_from_last
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      init_attributes_for_new_template
      return if request.xhr?
      render :template => 'tasks/new'
    end
  end

  def view
      redirect_to :action => 'edit', :id => params[:id]
  end

  def edit
    @task = controlled_model.accessed_by(current_user).find_by_task_num(params[:id])

    @ajax_task_links = request.xhr? # want to use ajax task loads if this page was loaded by ajax


    if @task.nil?
      flash['notice'] = _("You don't have access to that task, or it doesn't exist.")
      redirect_from_last
      return
    end

    init_form_variables(@task)
    set_last_task(@task)
    @task.set_task_read(current_user)

    respond_to do |format|
      format.html { render :template=> 'tasks/edit'}
      format.js { render(:template=>'tasks/edit', :layout => false) }
    end
  end

  def update
    @update_type = :updated

    @task = controlled_model.accessed_by(current_user).find_by_id( params[:id], :include => [:tags] )
    if @task.nil?
      flash['notice'] = _("You don't have access to that task, or it doesn't exist.")
      redirect_from_last
      return
    end

    unless current_user.can?(@task.project,'edit')
      flash['notice'] = ProjectPermission.message_for('edit')
      redirect_from_last
      return
    end

    @old_tags = @task.tags.collect {|t| t.name}.sort.join(', ')
    @old_deps = @task.dependencies.collect { |t| "[#{t.issue_num}] #{t.name}" }.sort.join(', ')
    @old_users = @task.owners.collect{ |u| u.id}.sort.join(',')
    @old_users ||= "0"
    @old_project_id = @task.project_id
    @old_project_name = @task.project.name
    @old_task = @task.clone

    if params[:task][:status].to_i == (Task::MAX_STATUS+1)
      params[:task][:status] = @task.status  # We're hiding the task, set the status to what is was.
    else
      params[:task][:hide_until] = @task.hide_until
    end

    @task.attributes = params[:task]

    begin
      ActiveRecord::Base.transaction do
        @task.save!

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
        @task.set_users_dependencies_resources(params, current_user)
        @task.duration = parse_time(params[:task][:duration], true) if (params[:task] && params[:task][:duration])
        @task.updated_by_id = current_user.id

        if @task.resolved? && @task.completed_at.nil?
          @task.completed_at = Time.now.utc

          # Repeat this task every X...
          if @task.next_repeat_date != nil
            @task.save!
            @task.reload
            @task.repeat_task
          end
        end

        if !@task.resolved? && !@task.completed_at.nil?
          @task.completed_at = nil
        end

        @task.scheduled_duration = @task.duration if @task.scheduled? && @task.duration != @old_task.duration
        @task.scheduled_at = @task.due_at if @task.scheduled? && @task.due_at != @old_task.due_at
        @task.save!

        @task.reload

        big_fat_controller_method
      end

      return if request.xhr?

      flash['notice'] ||= "#{ link_to_task(@task) } - #{_('Task was successfully updated.')}"
      redirect_to "/#{tasks_or_templates}/list"
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      init_form_variables(@task)
      render :template => 'tasks/edit'
    end
  end

  def ajax_hide
    @task = Task.accessed_by(current_user).find(params[:id])

    unless @task.hidden == 1
      @task.hidden = 1
      @task.updated_by_id = current_user.id
      @task.save

      worklog = WorkLog.new
      worklog.user = current_user
      worklog.for_task(@task)
      worklog.log_type = EventLog::TASK_ARCHIVED
      worklog.body = ""
      worklog.save
    end

    render :nothing => true
  end

  def ajax_restore
    @task = Task.accessed_by(current_user).find(params[:id])
    unless @task.hidden == 0
      @task.hidden = 0
      @task.updated_by_id = current_user.id
      @task.save

      worklog = WorkLog.new
      worklog.user = current_user
      worklog.for_task(@task)
      worklog.log_type = EventLog::TASK_RESTORED
      worklog.body = ""
      worklog.save
    end
    render :nothing => true
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

  def get_csv
    list_init
    filename = "clockingit_tasks.csv"
    @tasks= current_task_filter.tasks
    csv_string = FasterCSV.generate( :col_sep => "," ) do |csv|
      csv << Task.csv_header
      @tasks.each do |t|
        csv << t.to_csv
      end

    end
    logger.info("Seinding[#{filename}]")

    send_data(csv_string,
              :type => 'text/csv; charset=utf-8; header=present',
              :filename => filename)
  end

  def toggle_history
    session[:only_comments] ||= false
    session[:only_comments] = ! session[:only_comments]

    @task = Task.accessed_by(current_user).find(params[:id])
  end

  ###
  # This action just sets the unread status for a task.
  ###
  def set_unread
    task = Task.accessed_by(current_user).find_by_task_num(params[:id])
    user = current_user
    user = current_user.company.users.find(params[:user_id]) if !params[:user_id].blank?

    if task
      read = params[:read] != "false"
      task.set_task_read(user, read)
    end

    render :text => "", :layout => false
  end

  def add_notification
    @task = current_company_task_new
    if !params[:id].blank?
      @task = controlled_model.accessed_by(current_user).find(params[:id])
    end

    user = current_user.company.users.find(params[:user_id])
    @task.task_watchers.build(:user => user)

    render(:partial => "tasks/notification", :locals => { :notification => user })
  end

  def add_client
    @task = current_company_task_new
    if !params[:id].blank?
      @task = controlled_model.accessed_by(current_user).find(params[:id])
    end

    customer = current_user.company.customers.find(params[:client_id])
    @task.task_customers.build(:customer => customer)

    render(:partial => "tasks/task_customer", :locals => { :task_customer => customer })
  end

  def add_users_for_client
   @task = current_company_task_new
    if params[:id].present?
      @task = controlled_model.accessed_by(current_user).find(params[:id])
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
      res += render_to_string(:partial => "tasks/notification", :object => user)
    end

    render :text => res
  end

  def add_client_for_project
    project = current_user.projects.find(params[:project_id])
    res = ""

    if project
      res = render_to_string(:partial => "tasks/task_customer",
                             :object => project.customer)
    end

    render :text => res
  end

  def update_work_log
    log = WorkLog.accessed_by(current_user).find(params[:id])
    updated = log.update_attributes(params[:work_log])

    render :text => updated.to_s
  end
protected
  def create_attachments(task)
    filenames = []
    unless params['tmp_files'].blank? || params['tmp_files'].select{|f| f != ""}.size == 0
      params['tmp_files'].each do |tmp_file|
        next if tmp_file.is_a?(String)
        task_file = ProjectFile.new()
        task_file.company = current_user.company
        task_file.customer = task.project.customer
        task_file.project = task.project
        task_file.task_id = task.id
        task_file.user_id = current_user.id
        task_file.file=tmp_file
        task_file.save!

        filenames << task_file.file_file_name
      end
    end
    return filenames
  end
  ###
  # Sets up the attributes needed to display new action
  ###
  def init_attributes_for_new_template
    @projects = current_user.projects.find(:all, :order => 'name', :conditions => ["completed_at IS NULL"]).collect {  |c|
      [ "#{c.name} / #{c.customer.name}", c.id ] if current_user.can?(c, 'create')
    }.compact unless current_user.projects.nil?
      @tags = Tag.top_counts(current_user.company)
  end
  ###
  # Sets up the global variables needed to display the _form partial.
  ###
  def init_form_variables(task)
    task.due_at = tz.utc_to_local(@task.due_at) unless task.due_at.nil?
    @tags = {}

    @projects = User.find(current_user.id).projects.find(:all, :order => 'name', :conditions => ["completed_at IS NULL"]).collect {|c| [ "#{c.name} / #{c.customer.name}", c.id ] if current_user.can?(c, 'create')  }.compact unless current_user.projects.nil?
  end

  # setup some instance variables for task list views
  def list_init
    @ajax_task_links = true
  end

################################################
  def task_due_changed(old_task, task)
    if old_task.due_at != task.due_at
      old_name = "None"
      old_name = current_user.tz.utc_to_local(old_task.due_at).strftime_localized("%A, %d %B %Y") unless old_task.due_at.nil?
      new_name = "None"
      new_name = current_user.tz.utc_to_local(task.due_at).strftime_localized("%A, %d %B %Y") unless task.due_at.nil?

      return  "- <strong>Due</strong>: #{old_name} -> #{new_name}\n"
    else
      return ""
    end
  end
  def task_name_changed(old_task, task)
    (old_task[:name] != task[:name]) ? "- <strong>Name</strong>: #{old_task[:name]} -> #{task[:name]}\n" : ""
  end
  def task_description_changed(old_task, task)
    (old_task.description != task.description) ? "- <strong>Description</strong> changed\n" : ""
  end
  def task_duration_changed(old_task, task)
     (old_task.duration != task.duration) ? "- <strong>Estimate</strong>: #{worked_nice(old_task.duration).strip} -> #{worked_nice(task.duration)}\n" : ""
  end
############### This methods extracted to make Template Method design pattern #############################################3
  def current_company_task_new
    task=Task.new
    task.company=current_user.company
    return task
  end
  #this function abstract calls to model from  controller
  def controlled_model
    Task
  end
  def tasks_for_list
    session[:jqgrid_sort_column]= params[:sidx] unless params[:sidx].nil?
    session[:jqgrid_sort_order] = params[:sord] unless params[:sord].nil?
    current_task_filter.tasks_for_jqgrid(params)
  end
  #this method so big and complicated, so I can't find proper name for it
  #TODO: split this method into logical parts
  #NOTE: controller must not  have big fat methods
  def big_fat_controller_method
    body = ""
    body << task_name_changed(@old_task, @task)
    body << task_description_changed(@old_task, @task)

    assigned_ids = (params[:assigned] || [])
    assigned_ids = assigned_ids.uniq.collect { |u| u.to_i }.sort.join(',')
    if @old_users != assigned_ids
      @task.users.reload
      new_name = @task.owners.empty? ? 'Unassigned' : @task.owners.collect{ |u| u.name}.join(', ')
      body << "- <strong>Assignment</strong>: #{new_name}\n"
      @update_type = :reassigned
    end

    if @old_project_id != @task.project_id
      body << "- <strong>Project</strong>: #{@old_project_name} -> #{@task.project.name}\n"
      WorkLog.update_all("customer_id = #{@task.project.customer_id}, project_id = #{@task.project_id}", "task_id = #{@task.id}")
      ProjectFile.update_all("customer_id = #{@task.project.customer_id}, project_id = #{@task.project_id}", "task_id = #{@task.id}")
    end

    body<< task_duration_changed(@old_task, @task)

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

    body << task_due_changed(@old_task, @task)

    new_tags = @task.tags.collect {|t| t.name}.sort.join(', ')
    if @old_tags != new_tags
      body << "- <strong>Tags</strong>: #{new_tags}\n"
    end

    new_deps = @task.dependencies.collect { |t| "[#{t.issue_num}] #{t.name}"}.sort.join(", ")
    if @old_deps != new_deps
       body << "- <strong>Dependencies</strong>: #{(new_deps.length > 0) ? new_deps : _("None")}"
    end

    worklog = WorkLog.new
    worklog.log_type = EventLog::TASK_MODIFIED


    if @old_task.status != @task.status
      body << "- <strong>Resolution</strong>: #{@old_task.status_type} -> #{@task.status_type}\n"

      worklog.log_type = EventLog::TASK_COMPLETED if @task.resolved?
      worklog.log_type = EventLog::TASK_REVERTED if (@task.open? || (!@task.resolved? && @old_task.resolved?))

      if( @task.resolved? && @old_task.status != @task.status )
        @update_type = :status
      end

      if( @task.completed_at && @old_task.completed_at.nil?)
        @update_type = :completed
      end

      if( !@task.resolved? && @old_task.resolved? )
        @update_type = :reverted
      end

      if( @old_task.status == (Task::MAX_STATUS+1) )
        @task.hide_until = nil
      end
    end

    files = create_attachments(@task)
    files.each do |filename|
      body << "- <strong>Attached</strong>: #{filename}\n"
    end


    if body.length == 0
      #task not changed
      second_worklog=WorkLog.build_work_added_or_comment(@task, current_user, params)
      if second_worklog
        @task.save!
        second_worklog.save!
        second_worklog.send_notifications if second_worklog.comment?
      end
    else
      worklog.body=body
      if params[:comment] && params[:comment].length > 0
        worklog.comment = true
        worklog.body << "\n"
        worklog.user_input_add params[:comment]
      end
      worklog.user = current_user
      worklog.for_task(@task)
      worklog.access_level_id= (params[:work_log].nil? or params[:work_log][:access_level_id].nil?) ? 1 : params[:work_log][:access_level_id]
      worklog.save!
      worklog.send_notifications(@update_type) if worklog.comment?
      if params[:work_log] && !params[:work_log][:duration].blank?
        WorkLog.build_work_added_or_comment(@task, current_user, params)
        @task.save!
        #not send any emails
      end
    end
  end
  def create_worklogs_for_tasks_create
        WorkLog.build_work_added_or_comment(@task, current_user, params)
        @task.save! #FIXME: it saves worklog from line above
        WorkLog.create_task_created!(@task, current_user)
  end
  def tasks_or_templates
    "tasks"
  end
  def set_last_task(task)
    session[:last_task_id] = task.id
  end
  #this function copy todos from task template to task
  #NOTE: this code is very fragile
  #TODO: find sophisticated solution
  def copy_todos_from_template(id, task)
    return unless id.to_i > 0
    template = Template.find_by_id(id,:conditions=>["company_id = ?", current_user.company_id])
    if template.nil?
      #this is not template, just regular task
      return
    end
    template.todos.each{|todo| task.todos<< todo.clone }
  end
end
