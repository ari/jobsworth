# encoding: UTF-8
# Handle tasks for a Company / User

require 'csv'

class TasksController < ApplicationController
  before_filter :check_if_user_has_projects,    :only => [:new, :create]
  before_filter :check_if_user_can_create_task, :only => [:create]
  before_filter :list_init, :only => [:index, :calendar, :get_csv]

  cache_sweeper :tag_sweeper, :only =>[:create, :update]
  cache_sweeper :task_sweeper
  cache_sweeper :work_log_sweeper

  def index
    #TODO: Code smell, we should be dealing only with collections here
    @task   = Task.accessed_by(current_user).find_by_id(session[:last_task_id])
    @tasks  = tasks_for_list

    respond_to do |format|
      format.html { render :action => "grid" }
      format.json { render :template => "tasks/index.json"}
    end
  end

  def new
    @task = current_company_task_new
    @task.task_num = nil
    # TODO: Set this default value on the db
    @task.duration = 0
    @task.watchers << current_user

    render 'tasks/new'
  end

  def create
    @task.task_due_calculation(params[:task][:due_at], current_user)
    @task.duration = parse_time(params[:task][:duration], true)
    @task.duration = 0 if @task.duration.nil?
    if @task.service_id == -1
      @task.isQuoted   = true
      @task.service_id = nil
    else
      @task.isQuoted = false
    end
    params[:todos].collect { |todo| @task.todos.build(todo) } if params[:todos]

    # One task can have two  worklogs, so following code can raise three exceptions
    # ActiveRecord::RecordInvalid or ActiveRecord::RecordNotSaved
    begin
      ActiveRecord::Base.transaction do
        begin
          @task.save!
        rescue ActiveRecord::RecordNotUnique
          @task.save!
        end
        @task.set_users_dependencies_resources(params, current_user)
        create_worklogs_for_tasks_create(@task.create_attachments(params['tmp_files'], current_user))
      end
      set_last_task(@task)

      flash[:success] ||= (link_to_task(@task) + " - #{_('Task was successfully created.')}")
      Trigger.fire(@task, Trigger::Event::CREATED)
      return if request.xhr?
      redirect_to tasks_path
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      flash[:error] = @task.errors.full_messages.join(". ")
      return if request.xhr?
      render :template => 'tasks/new'
    end
  end

  def score
    @task = Task.find_by_task_num(params[:task_num])

    if @task.nil?
      flash[:error] = _'Invalid Task Number'
      redirect_to 'index'
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

  def calendar_resources
    @tasks=current_task_filter.tasks_for_fullcalendar(params)
    @tasks.collect! {|t| {:name => "<a href='/tasks/#{t.task_num}/edit'>#{t.name}</a>", :id => t.task_num }}

    render :json => @tasks
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

      # only return resources related to current selected customer
      params[:customer_ids] ||= []
      params[:customer_ids] = [0] if params[:customer_ids].empty?
      conds += "and (customer_id in (?))"
      cond_params << params[:customer_ids]

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

  def edit
    @task = controlled_model.accessed_by(current_user).find_by_task_num(params[:id])
    @ajax_task_links = request.xhr? # want to use ajax task loads if this page was loaded by ajax

    if @task.nil?
      flash[:error] = _("You don't have access to that task, or it doesn't exist.")
      redirect_from_last
      return
    end

    set_last_task(@task)
    @task.set_task_read(current_user)

    respond_to do |format|
      format.html { render :template=> 'tasks/edit'}
      format.js {
        html = render_to_string(:template=>'tasks/edit', :layout => false)
        render :json => { :html => html, :task_num => @task.task_num, :task_name => @task.name }
      }
    end
  end

  def update
    @task = controlled_model.accessed_by(current_user).includes(:tags).find_by_id(params[:id])
    if @task.nil?
      flash[:error] = _("You don't have access to that task, or it doesn't exist.")
      redirect_from_last and return
    end

    # TODO this should be a before_filter
    unless current_user.can?(@task.project,'edit') or current_user.can?(@task.project, 'comment')
      flash[:error] = ProjectPermission.message_for('edit')
      redirect_from_last and return
    end

    # if user only have comment rights
    if current_user.can?(@task.project, 'comment') and !current_user.can?(@task.project,'edit')
      params[:task] = {}
    end

    # TODO this should go into Task model
    begin
      ActiveRecord::Base.transaction do
        Task.update(@task, params, current_user)
      end

      # TODO this should be an observer
      Trigger.fire(@task, Trigger::Event::UPDATED)
      flash[:success] ||= link_to_task(@task) + " - #{_('Task was successfully updated.')}"

      respond_to do |format|
        format.html { redirect_to :action=> "edit", :id => @task.task_num  }
        format.js {
          render :json => {
            :status => :success,
            :tasknum => @task.task_num,
            :tags => render_to_string(:partial => "tags/panel_list.html.erb"),
            :message => render_to_string(:partial => "layouts/flash.html.erb", :locals => {:flash => flash}).html_safe }
        }

      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      flash[:error] = @task.errors.full_messages.join(". ")
      respond_to do |format|
        format.html { render :template=> 'tasks/edit' }
        format.js { render :json => {:status => :error, :messages => @task.errors.full_messages}.to_json }
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

  def refresh_service_options
    @task = current_company_task_new
    if params[:taskId]
      @task = Task.accessed_by(current_user).find(params[:taskId])
    end

    customers = []
    customerIds = []
    customerIds = params[:customerIds].split(',') if params[:customerIds]
    customerIds.each do |cid|
      customers << current_user.company.customers.find(cid)
    end

    render :json => {:success => true, :html => view_context.options_for_task_services(customers, @task) }
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

  # GET /tasks/billable?customer_ids=:customer_ids&project_id=:project_id&service_id=:service_id
  def billable
    @project = current_user.projects.find(params[:project_id]) if params[:project_id]
    return render :json => {:billable => false} if @project and @project.suppressBilling
    return render :json => {:billable => false} if params[:service_id].to_i < 0
    return render :json => {:billable => true} if params[:service_id].to_i == 0

    @customer_ids = (params[:customer_ids] || "").split(',')
    slas = []
    @customer_ids.each do |cid|
      customer = current_user.company.customers.find(cid) rescue nil

      if customer
        sla = customer.service_level_agreements.where(:service_id => params[:service_id]).first rescue nil
        slas << sla if sla
      end
    end

    sla = slas.detect {|s| s.billable}
    if sla
      return render :json => {:billable => true}
    else
      return render :json => {:billable => false}
    end
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

    @task && @task.customers.each do |customer|
      @users = @users + customer.users.active.where("id NOT IN (#{excluded_ids})").order('name').limit(50)
    end
    @users = @users.uniq.sort_by{|user| user.name}.first(50)

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
    return render :json => { :success => false } if moved.nil?

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
    render :json => { :success => true }
  end

  # build 'next tasks' panel from an ajax call (click on the more... button)
  def nextTasks
    render :partial => "nextTasks", :locals => { :count => params[:count].to_i }
  end

  protected

  def check_if_user_can_create_task
    @task = current_company_task_new
    @task.attributes = params[:task]

    unless current_user.can?(@task.project, 'create')
      flash[:error] = _("You don't have access to create tasks on this project.")
      render :new
    end
  end

  def check_if_user_has_projects
    unless current_user.has_projects?
      flash[:error] = _("You need to create a project to hold your tasks.")
      redirect_to new_project_path
    end
  end

  def hide_task(id, hide=1)
    task = Task.accessed_by(current_user).find(id)
    unless task.hidden == hide
      task.hidden = hide
      task.save

      event_log = EventLog.new(:user => current_user, :target => task)
      event_log.event_type =  hide == 1 ? EventLog::TASK_ARCHIVED : EventLog::TASK_RESTORED
      event_log.body = ""
      event_log.save
    end
  end

  # setup some instance variables for task list views
  def list_init
    @ajax_task_links = true
  end

############### This methods extracted to make Template Method design pattern #############################################3
  def current_company_task_new
    return Task.new(:company => current_user.company)
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

  def create_worklogs_for_tasks_create(files)
    # task created
    work_log = WorkLog.create_task_created!(@task, current_user)
    work_log.notify(files)

    work_log = WorkLog.build_work_added_or_comment(@task, current_user, params)
    work_log.save if work_log
  end

  def set_last_task(task)
    session[:last_task_id] = task.id
  end
end
