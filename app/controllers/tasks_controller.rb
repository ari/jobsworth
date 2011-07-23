# encoding: UTF-8
# Handle tasks for a Company / User

require 'csv'

class TasksController < ApplicationController
  before_filter :check_if_user_has_projects, :only => [:new, :create]
  before_filter :list_init, :only => [:list, :calendar, :gantt, :get_csv]

  cache_sweeper :tag_sweeper, :only =>[:create, :update]
  cache_sweeper :task_sweeper

  def index
    @task   = Task.accessed_by(current_user).find_by_id(session[:last_task_id])
    @tasks  = tasks_for_list

    respond_to do |format|
      format.html { render :action => "grid" }
      format.json { render :template => "tasks/index.json"}
    end
  end

  def new
    @task = current_company_task_new
    @task.duration = 0
    @task.watchers << current_user
  end

  def score
    @task = Task.find_by_task_num(params[:task_num])

    if @task.nil?
      flash[:error] = _'Invalid Task Number'
      redirect_to 'list'
    else
      # Force score recalculation
      @task.save(:validation => false)
      @score_rules = @task.score_rules    
    end
  end

  
  def calendar
    respond_to do |format|
      format.html
      format.json{
        @tasks=current_task_filter.tasks_for_fullcalendar(params)
      }
    end
  end

  def gantt
  end

  def auto_complete_for_dependency_targets
    value = params[:term]
    value.gsub!(/#/, '')
    @keys = [ value ]
    @tasks = Task.search(current_user, @keys)
    render :json=> @tasks.collect{|task| {:label => "[##{task.task_num}] #{task.name}", :value=>task.name[0..13] + '...' , :id => task.task_num } }.to_json
  end

  def auto_complete_for_resource_name
    return if !current_user.use_resources?

    search = params[:term]
    search = search.split(",").last if search

    if !search.blank?
      conds = "lower(name) like ?"
      cond_params = [ "%#{ search.downcase }%" ]
      if params[:customer_id]
        conds += "and (customer_id is null or customer_id = ?)"
        cond_params << params[:customer_id]
      end

      conds = [ conds ] + cond_params

      @resources = current_user.company.resources.where(conds)
     render :json=> @resources.collect{|resource| {:label => "[##{resource.id}] #{resource.name}", :value => resource.name, :id=> resource.id} }.to_json
    else
      render :nothing=> true
    end
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

    @task = current_company_task_new
    @task.attributes = params[:task]
    task_due_calculation(params, @task, tz)
    @task.duration = parse_time(params[:task][:duration], true)
    @task.duration = 0 if @task.duration.nil?
    params[:todos].collect { |todo| @task.todos.build(todo) } if params[:todos]

    unless current_user.can?(@task.project, 'create')
      flash['notice'] = _("You don't have access to create tasks on this project.")
      return if request.xhr?
      render :template => 'tasks/new'
      return
    end
    #One task can have two  worklogs, so following code can raise three exceptions
    #ActiveRecord::RecordInvalid or ActiveRecord::RecordNotSaved
    begin
      ActiveRecord::Base.transaction do
        begin
          @task.save!
        rescue ActiveRecord::RecordNotUnique
          @task.save!
        end
        @task.set_users_dependencies_resources(params, current_user)
        create_worklogs_for_tasks_create(@task.create_attachments(params, current_user))
      end
      set_last_task(@task)

      flash['notice'] ||= (link_to_task(@task) + " - #{_('Task was successfully created.')}")
      Trigger.fire(@task, Trigger::Event::CREATED)
      return if request.xhr?
      redirect_to :action => :list
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      return if request.xhr?
      render :template => 'tasks/new'
    end
  end

  def edit
    @task = controlled_model.accessed_by(current_user).find_by_task_num(params[:id])

    @ajax_task_links = request.xhr? # want to use ajax task loads if this page was loaded by ajax


    if @task.nil?
      flash['notice'] = _("You don't have access to that task, or it doesn't exist.")
      redirect_from_last
      return
    end

    set_last_task(@task)
    @task.set_task_read(current_user)

    respond_to do |format|
      format.html { render :template=> 'tasks/edit'}
      format.js { render(:template=>'tasks/edit', :layout => false) }
    end
  end

  def update
    @task = controlled_model.accessed_by(current_user).includes(:tags).find_by_id(params[:id])
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
    if @task.wait_for_customer and !params[:comment].blank?
      @task.wait_for_customer=false
      params[:task].delete(:wait_for_customer)
    end
    @task.attributes = params[:task]

    begin
      ActiveRecord::Base.transaction do
        @changes = @task.changes
        @task.save!
        task_due_calculation(params, @task, tz)
        @task.set_users_dependencies_resources(params, current_user)
        @task.duration = parse_time(params[:task][:duration], true) if (params[:task] && params[:task][:duration])

        if @task.resolved? && @task.completed_at.nil?
          @task.completed_at = Time.now.utc
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
      Trigger.fire(@task, Trigger::Event::UPDATED)
      notice=link_to_task(@task) + " - #{_('Task was successfully updated.')}"
      respond_to do |format|
        format.html {
          flash['notice'] ||= notice
          redirect_to :action=> "list"
        }
        format.js {
          render :json => {:status => :success, :tasknum => @task.task_num,
            :tags => render_to_string(:partial => "tags/panel_list.html.erb"),
            :message=>render_to_string(:partial => "layouts/flash.html.erb", :locals => {:message => notice}).html_safe }.to_json
        }

      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      respond_to do |format|
        format.html {
          render :template => 'tasks/edit'
        }
        format.js {
          render :json => {:status => :error, :messages => @task.errors.full_messages}.to_json
        }
      end
    end
  end

  def ajax_hide
    hide_task(params[:id])
    render :nothing => true
  end

  def ajax_restore
    hide_task(params[:id], 0)
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

  def get_csv
    filename = "jobsworth_tasks.csv"
    @tasks= current_task_filter.tasks
    csv_string = CSV.generate( :col_sep => "," ) do |csv|
      csv << @tasks.first.csv_header
      @tasks.each do |t|
        csv << t.to_csv
      end

    end
    logger.info("Sending[#{filename}]")

    send_data(csv_string,
              :type => 'text/csv; charset=utf-8; header=present',
              :filename => filename)
  end

  def add_notification
    @task = current_company_task_new
    if !params[:id].blank?
      @task = controlled_model.accessed_by(current_user).find(params[:id])
    end

    user = current_user.company.users.active.find(params[:user_id])
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
      res += render_to_string(:partial => "tasks/notification", :collection => users)

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

  def set_group
    task = Task.accessed_by(current_user).find_by_task_num(params[:id])
    task.update_group(current_user, params[:group], params[:value], params[:icon])

    expire_fragment( %r{tasks\/#{task.id}-.*\/*} )
    render :nothing => true
  end

  def update_sheet_info
    render :partial => "/layouts/sheet_info"
  end

  def users_to_notify_popup
    # anyone already attached to the task should be removed
    excluded_ids = params[:watcher_ids].blank? ? 0 : params[:watcher_ids]
    @users = current_user.customer.users.active.where("id NOT IN (#{excluded_ids})").order('name').limit(50)
    @task = controlled_model.accessed_by(current_user).find_by_id(params[:id])
    if @task && current_user.customer != @task.project.customer
      @users = @users + @task.project.customer.users.active.where("id NOT IN (#{excluded_ids})")
      @users = @users.uniq.sort_by{|user| user.name}.first(50)
    end
    render :layout =>false
  end

  # The user has dragged a task into a different order and we need to adjust the weight adjustment accordingly
  def change_task_weight

    # Note that we check the user has access to this task before moving it
    moved = Task.accessed_by(current_user).find_by_id(params[:moved])
    return if (moved.nil?)

    # If prev is not passed, then the user wanted to move the task to the top of the list
    if (params[:prev])
      prev = Task.find_by_id(params[:prev])
    end
    
    if prev.nil?
      topTask = Task.joins(:owners).where(:users => {:id => current_user}).order("tasks.weight DESC").limit(1).first
      changeRequired = topTask.weight - moved.weight + 1
    else
      changeRequired = prev.weight - moved.weight - 1
    end
    moved.weight_adjustment = moved.weight_adjustment + changeRequired
    moved.weight = moved.weight + changeRequired
    moved.save(:validate => false)
    render :nothing => true
  end
  
  # build 'next tasks' panel from an ajax call (click on the more... button)
  def nextTasks
    render :partial => "nextTasks", :locals => { :count => params[:count].to_i }
  end
  
  protected

  def check_if_user_has_projects
    unless current_user.has_projects?
      flash['notice'] = _("You need to create a project to hold your tasks, or get access to create tasks in an existing project...")
      redirect_to new_project_path
    end
  end

  def task_due_calculation(params, task, tz)
    if !params[:task].nil? && !params[:task][:due_at].nil? && params[:task][:due_at].length > 0
      begin
        due_date = DateTime.strptime( params[:task][:due_at], current_user.date_format )
      rescue
        flash['notice'] = _('Invalid due date ignored.')
        due_date = nil
      end
      task.due_at = tz.local_to_utc(due_date.to_time) unless due_date.nil?
    end
  end

  def hide_task(id, hide=1)
    task = Task.accessed_by(current_user).find(id)
    unless task.hidden == hide
      task.hidden = hide
      task.save

      worklog = WorkLog.new(:user=> current_user)
      worklog.for_task(task)
      worklog.log_type =  hide == 1 ? EventLog::TASK_ARCHIVED : EventLog::TASK_RESTORED
      worklog.body = ""
      worklog.save
    end
  end

  # setup some instance variables for task list views
  def list_init
    @ajax_task_links = true
  end

################################################
  def task_name_changed(old_task, task)
    (old_task[:name] != task[:name]) ? ("- Name:".html_safe  + "#{old_task[:name]} " + "->".html_safe + " #{task[:name]}\n") : ""
  end
  def task_description_changed(old_task, task)
    (old_task.description != task.description) ? "- Description changed\n".html_safe : ""
  end
############### This methods extracted to make Template Method design pattern #############################################3
  def current_company_task_new
    return Task.new(:company=>current_user.company)
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

    worklog = WorkLog.new(:log_type => EventLog::TASK_MODIFIED)

    assigned_ids = (params[:assigned] || [])
    assigned_ids = assigned_ids.uniq.collect { |u| u.to_i }.sort.join(',')
    if @old_users != assigned_ids
      @task.users.reload
      new_name = @task.owners.empty? ? 'Unassigned' : @task.owners.collect{ |u| u.name}.join(', ')
      body << "- Assignment: #{new_name}\n"
      worklog.log_type = EventLog::TASK_ASSIGNED
    end

    if @old_project_id != @task.project_id
      body << "- Project: #{@old_project_name} -> #{@task.project.name}\n"
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
      body << "- Milestone: #{old_name} -> #{new_name}\n"
    end

    body << task_due_changed(@old_task, @task)

    new_tags = @task.tags.collect {|t| t.name}.sort.join(', ')
    if @old_tags != new_tags
      body << "- Tags: #{new_tags}\n"
    end

    new_deps = @task.dependencies.collect { |t| "[#{t.issue_num}] #{t.name}"}.sort.join(", ")
    if @old_deps != new_deps
       body << "- Dependencies: #{(new_deps.length > 0) ? new_deps : _("None")}"
    end

    if @old_task.status != @task.status
      body << "- Resolution: #{@old_task.status_type} -> #{@task.status_type}\n"

      if( @task.resolved? && @old_task.status != @task.status )
        worklog.log_type = EventLog::TASK_MODIFIED
      end

      if( @task.completed_at && @old_task.completed_at.nil?)
        worklog.log_type = EventLog::TASK_COMPLETED
      end

      if( !@task.resolved? && @old_task.resolved? )
        worklog.log_type = EventLog::TASK_REVERTED
      end
    end

    files = @task.create_attachments(params, current_user)
    files.each do |file|
      body << "- Attached: #{file.file_file_name}\n"
    end


    if body.length == 0
      #task not changed
      second_worklog=WorkLog.build_work_added_or_comment(@task, current_user, params)
      if second_worklog
        @task.save!
        second_worklog.save!
        second_worklog.notify(files) if second_worklog.comment?
      end
    else
      worklog.body=body
      if params[:comment] && params[:comment].length > 0
        worklog.comment = true
        worklog.body << "\n"
        worklog.body << params[:comment]
      end
      worklog.for_task(@task)
      worklog.access_level_id= (params[:work_log].nil? or params[:work_log][:access_level_id].nil?) ? 1 : params[:work_log][:access_level_id]
      worklog.save!
      worklog.notify(files) if worklog.comment?
      if params[:work_log] && !params[:work_log][:duration].blank?
        WorkLog.build_work_added_or_comment(@task, current_user, params)
        @task.save!
        #not send any emails
      end
    end
  end
  def create_worklogs_for_tasks_create(files)
    WorkLog.build_work_added_or_comment(@task, current_user, params)
    @task.save! #FIXME: it saves worklog from line above
    WorkLog.create_task_created!(@task, current_user)
    if @task.work_logs.first.comment?
      @task.work_logs.first.notify(files)
    else
      @task.work_logs.last.notify(files)
    end
  end
  def set_last_task(task)
    session[:last_task_id] = task.id
  end
end
