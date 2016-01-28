# encoding: UTF-8
# Handle tasks for a Company / User

require 'csv'

class TasksController < ApplicationController
  before_filter :check_if_user_has_projects,    :only => [:new, :create]
  before_filter :check_if_user_can_create_task, :only => [:create]
  before_filter :authorize_user_is_admin, :only => [:planning]

  cache_sweeper :tag_sweeper, :only =>[:create, :update]

  def index
    @task   = TaskRecord.accessed_by(current_user).find_by_id(session[:last_task_id])
    @tasks = current_task_filter.tasks
    @owners = []
    @tasks.each do |task|
      task.owners.each do |owner|
        unless @owners.include? owner
          @owners << owner
          owner.schedule_tasks ({:save => true})
        end
      end
    end
    @top_next_task = current_user.top_next_task

    respond_to do |format|
      format.html
      format.json { render :template => "tasks/index.json"}
    end
  end

  def new
    @task = create_entity
    @task.task_num = nil
    # TODO: Set this default value on the db
    @task.duration = 0
    @task.watchers << current_user

    render 'tasks/new'
  end

  def create
    @task.task_due_calculation(params[:task][:due_at], current_user)
    @task.duration = TimeParser.parse_time(params[:task][:duration])
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
        files = @task.create_attachments(params['tmp_files'], current_user)
        create_worklogs_for_tasks_create(files) if @task.is_a?(TaskRecord)
      end
      set_last_task(@task)

      flash[:success] ||= (link_to_task(@task) + " - #{t('flash.notice.model_created', model: TaskRecord.model_name.human)}")
      Trigger.fire(@task, Trigger::Event::CREATED)
      return if request.xhr?
      redirect_to tasks_path
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      flash[:error] = @task.errors.full_messages.join(". ")
      return if request.xhr?
      render :template => 'tasks/new'
    end
  end

  def calendar
    respond_to do |format|
      format.html
      format.json{
        @tasks = current_task_filter.tasks_for_fullcalendar(params)
      }
    end
  end

  def gantt
    respond_to do |format|
      format.html
      format.json{
        @tasks = current_task_filter.tasks_for_gantt(params)
      }
    end
  end

  def auto_complete_for_dependency_targets
    value = params[:term]
    value.gsub!(/#/, '')
    @keys = [ value ]
    @tasks = TaskRecord.search(current_user, @keys, status_in: AbstractTask::OPEN)
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
    dependency = TaskRecord.accessed_by(current_user).find_by_task_num(params[:dependency_id])
    render(:partial => "dependency",
           :locals => { :dependency => dependency, :perms => {} })
  end

  def edit
    @task = AbstractTask.accessed_by(current_user).find_by_task_num(params[:id])

    if @task.nil?
      flash[:error] = t('flash.error.not_exists_or_no_permission', model: TaskRecord.model_name.human)
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
    @task = AbstractTask.accessed_by(current_user).find_by_id(params[:id])
    if @task.nil?
      flash[:error] = t('flash.error.not_exists_or_no_permission', model: TaskRecord.model_name.human)
      redirect_from_last and return
    end

    # TODO this should be a before_filter
    unless task_edit_permissions? (['edit', 'comment', 'milestone'])
      flash[:error] = ProjectPermission.message_for('edit')
      redirect_from_last and return
    end

    # if user only have comment rights
    if !task_edit_permissions? (['edit', 'milestone']) and task_edit_permissions? (['comment'])
      params[:task] = {}
    end

    # TODO this should go into Task model
    begin
      ActiveRecord::Base.transaction do
        TaskRecord.update(@task, params, current_user)
      end

      # TODO this should be an observer
      Trigger.fire(@task, Trigger::Event::UPDATED)
      flash[:success] ||= link_to_task(@task) + " - #{t('flash.notice.model_updated', model: TaskRecord.model_name.human)}"

      respond_to do |format|
        format.html { redirect_to :action=> "edit", :id => @task.task_num  }
        format.js {
          render :json => {
            :status => :success,
            :tasknum => @task.task_num,
            :tags => render_to_string(:partial => "tags/panel_list"),
            :message => render_to_string(:partial => "layouts/flash", :locals => {:flash => flash}).html_safe }
        }

      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      respond_to do |format|
        format.html {
          flash[:error] = @task.errors.full_messages.join(". ")
          render :template=> 'tasks/edit'
        }
        format.js { render :json => {:status => :error, :messages => @task.errors.full_messages}.to_json }
      end
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

  def refresh_service_options
    @task = create_entity
    if params[:taskId]
      @task = AbstractTask.accessed_by(current_user).find(params[:taskId])
    end

    customers = []
    customerIds = []
    customerIds = params[:customerIds].split(',') if params[:customerIds]
    customerIds.each do |cid|
      customers << current_user.company.customers.find(cid)
    end

    render :json => {:success => true, :html => view_context.options_for_task_services(customers, @task) }
  end

  def get_watcher
    @task = create_entity
    if !params[:id].blank?
      @task = AbstractTask.accessed_by(current_user).find_by_id(params[:id])
    end

    user = current_user.company.users.active.find(params[:user_id])
    @task.task_watchers.build(:user => user)

    render(:partial => "tasks/notification", :locals => { :notification => user })
  end

  def get_customer
    @task = create_entity
    if !params[:id].blank?
      @task = AbstractTask.accessed_by(current_user).find_by_id(params[:id])
    end

    customer = current_user.company.customers.find(params[:customer_id])
    @task.task_customers.build(:customer => customer)

    render(:partial => "tasks/task_customer", :locals => { :task_customer => customer })
  end

  def get_default_customers
    @task = create_entity
    if !params[:id].blank?
      @task = AbstractTask.accessed_by(current_user).find_by_id(params[:id])
    end

    @project = current_user.projects.find_by_id(params[:project_id])

    @customers = []
    @customers << @project.customer
    @customers += @task.customers

    render(:partial => "tasks/task_customer", :collection => @customers, :as => :task_customer)
  end

  def get_default_watchers_for_customer
    @task = create_entity
    if !params[:id].blank?
      @task = AbstractTask.accessed_by(current_user).find_by_id(params[:id])
    end

    if params[:customer_id].present?
      @customer = current_user.company.customers.find(params[:customer_id])
    end

    users = @customer ? @customer.users.auto_add.all : []
    users.reject! {|u| @task.users.include?(u) }

    res = render_to_string(:partial => "tasks/notification", :collection => users)
    render :text => res
  end

  def get_default_watchers_for_project
    @task = create_entity
    if !params[:id].blank?
      @task = AbstractTask.accessed_by(current_user).find_by_id(params[:id])
    end
    @existing_users = User.where("name in (?)", params[:users])
    users = []
    if params[:project_id].present?
      users = Project.find(params[:project_id]).default_users
    end
    users.reject! {|u| @task.users.include?(u) && @existing_users.include?(u) }
    res = render_to_string(:partial => "tasks/notification",:collection => users)
    render :text => res
  end

  def get_default_watchers
    @task = create_entity
    if !params[:id].blank?
      @task = AbstractTask.accessed_by(current_user).find_by_id(params[:id])
    end

    @customers = []
    if params[:customer_ids].present?
      @customers = current_user.company.customers.where("customers.id IN (?)", params[:customer_ids])
    end

    if params[:project_id].present?
      @default_users = User.joins("INNER JOIN default_project_users on default_project_users.user_id = users.id").where("default_project_users.project_id = ?", params[:project_id])
      @project = current_user.projects.find_by_id(params[:project_id])
      @customers << @project.customer if @project.try(:customer)
    end

    @users = [current_user]
    @customers.each {|c| @users += c.users.auto_add.all }
    @users += @task.users
    @users += @default_users
    @users.uniq!

    res = render_to_string(:partial => "tasks/notification", :collection => @users)
    render :text => res
  end

  # GET /tasks/billable?customer_ids=:customer_ids&project_id=:project_id&service_id=:service_id
  def billable
    @project = current_user.projects.find(params[:project_id]) if params[:project_id]
    return render :json => {:billable => false} if @project and @project.no_billing?
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
    task = TaskRecord.accessed_by(current_user).find_by_task_num(params[:id])
    task.update_group(current_user, params[:group], params[:value], params[:icon])

    expire_fragment( %r{tasks\/#{task.id}-.*\/*} )
    render :nothing => true
  end

  def users_to_notify_popup
    # anyone already attached to the task should be removed
    excluded_ids = params[:watcher_ids].blank? ? 0 : params[:watcher_ids]
    @users = current_user.customer.users.active.where("id NOT IN (#{excluded_ids})").order('name').limit(50)
    @task = AbstractTask.accessed_by(current_user).find_by_id(params[:id])

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
    @user = current_user
    if current_user.admin? and params[:user_id]
      @user = current_user.company.users.find(params[:user_id])
    end

    # Note that we check the user has access to this task before moving it
    moved = TaskRecord.accessed_by(@user).find_by_id(params[:moved])
    return render :json => { :success => false } if moved.nil?

    # If prev is not passed, then the user wanted to move the task to the top of the list
    if (params[:prev])
      prev = TaskRecord.accessed_by(@user).find_by_id(params[:prev])
    end

    if prev.nil?
      topTask = @user.tasks.open_only.not_snoozed.order("weight DESC").first
      changeRequired = topTask.weight - moved.weight + 1
    else
      changeRequired = prev.weight - moved.weight - 1
    end
    moved.weight_adjustment = moved.weight_adjustment + changeRequired
    moved.weight = moved.weight + changeRequired
    moved.save(:validate => false)
    render :json => { :success => true }
  end

  # GET /tasks/planning
  def planning
    @users = current_user.company.users.active.order("name ASC")
    render :layout => "layouts/basic"
  end

  def clone
    @template = current_templates.find_by_task_num(params[:id])
    @task = TaskRecord.new(@template.as_json['template'])
    @from_template = 1
    @task.tags = @template.tags
    @task.todos = @template.todos.order("todos.id")
    @task.customers = @template.customers
    @task.users = @template.users
    @task.watchers = @template.watchers
    @task.owners = @template.owners
    @task.task_property_values = @template.task_property_values
    render 'tasks/new'
  end

  # GET /tasks/score/:id
  def score
    @task = TaskRecord.accessed_by(current_user).find_by_task_num(params[:id])
    if @task.nil?
      flash[:error] = t('activerecord.errors.models.task_record.task_number.invalid')
      redirect_to 'index'
    else
      # Force score recalculation
      @task.save(:validation => false)
    end
  end

  # build 'next tasks' panel from an ajax call (click on the more... button)
  def nextTasks
    @user = current_user
    if current_user.admin? and params[:user_id]
      @user = current_user.company.users.find(params[:user_id])
    end

    html = render_to_string :partial => "tasks/next_tasks_panel", :locals => { :count => params[:count].to_i, :user => @user }
    render :json => { :html => html, :has_more => (@user.tasks.open_only.not_snoozed.count > params[:count].to_i) }
  end

  def task_edit_permissions? (permissions)
    #This method returns true if the user has atleast one of the permissions
    permission = false
    permissions.each do |p|
      permission = true if current_user.can?(@task.project, p)
    end
    permission
  end

  protected

  def check_if_user_can_create_task
    @task = create_entity
    @task.attributes = params[:task]

    unless current_user.can?(@task.project, 'create')
      flash[:error] = t('flash.alert.unauthorized_operation')
      render :new
    end
  end

  def check_if_user_has_projects
    unless current_user.has_projects?
      redirect_to new_project_path, alert: t('hint.task.project_needed')
    end
  end

############### This methods extracted to make Template Method design pattern #############################################3
  def create_entity
    return TaskRecord.new(:company => current_user.company)
  end

  def create_worklogs_for_tasks_create(files)
    # task created
    work_log = WorkLog.create_task_created!(@task, current_user)
    work_log.notify(files)

    work_log = WorkLog.build_work_added_or_comment(@task, current_user, params)
    work_log.save if work_log
  end

  def set_last_task(task)
    session[:last_task_id] = task.id if task.is_a?(TaskRecord)
  end
end
