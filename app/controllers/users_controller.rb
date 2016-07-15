# encoding: UTF-8
class UsersController < ApplicationController

  before_filter :protected_area, :except => [:update_seen_news, :avatar, :auto_complete_for_project_name, :auto_complete_for_user_name]

  def index
    @users = User.where('users.company_id = ?', current_user.company_id)
                 .includes(:project_permissions => {:project => :customer})
                 .order('users.name')
                 .paginate(:page => params[:page], :per_page => 100)
  end

  def new
    @user = User.new(user_create_params)
    @user.company_id = current_user.company_id
    @user.customer_id = current_user.customer_id if @user.customer_id.blank?
    @user.time_zone = current_user.time_zone
    @user.create_projects = 0
    @user.option_tracktime = 0
    @user.build_work_plan

    render :layout => 'basic'
  end

  def create
    @user = User.new(user_create_params)
    @user.company_id = current_user.company_id
    @user.email = params[:email]

    if @user.errors.size > 0
      flash[:error] = @user.errors.full_messages.join('. ')
      return render :action => 'new'
    end

    if @user.save
      if params[:copy_user].to_i > 0
        u = current_user.company.users.find(params[:copy_user])
        u.project_permissions.each do |perm|
          p = perm.dup
          p.user = @user
          p.save
        end
      end

      flash[:success] = t('flash.notice.model_created', model: User.model_name.human) +
          t('hint.user.add_permissions')

      if params[:send_welcome_email]
        begin
          Signup.account_created(@user, current_user, params['welcome_message']).deliver
        rescue
          flash[:error] ||= ''
          flash[:error] += ('<br/>' + t('error.user.send_creation_email')).html_safe
        end
      end

      redirect_to edit_user_path(@user)
    else
      flash[:error] = @user.errors.full_messages.join('. ')
      render :action => 'new'
    end
  end

  def edit
  end

  def access
    if request.put?
      if current_user.admin?
        flash[:success] = t('flash.notice.model_updated', model: t('users.access_control'))
        @user.set_access_control_attributes(user_access_params)
        @user.save!
      end
    end

    if !current_user.admin?
      flash[:error] = t('flash.alert.access_denied_to_model', model: t('users.access_control'))
      redirect_to edit_user_path(@user)
    end
  end

  def emails
  end

  def tasks
    redirect_to [:workplan, @user]
  end

  def filters
    @private_filters = @user.private_task_filters.order('task_filters.name')
    @shared_filters = @user.shared_task_filters.order('task_filters.name')
  end

  def projects
  end

  def workplan
    @user_recent_work_logs = @user.work_logs.order(:started_at).reverse_order.includes(:task).limit(10)
    if request.put?
      if @user.work_plan.update_attributes(work_plan_params)
        flash[:success] = t('flash.notice.model_updated', model: WorkPlan.model_name.human)
      else
        flash[:error] = @user.work_plan.errors.full_messages.join(', ')
      end
    end
  end

  def update
    @user = User.where('company_id = ?', current_user.company_id).find(params[:id])
    if @user.update_attributes(user_update_params)
      flash[:success] = t('flash.notice.model_updated', model: User.model_name.human)
      redirect_to edit_user_path(@user)
    else
      flash[:error] = @user.errors.full_messages.join('. ')
      render :action => 'edit', :layout => 'basic'
    end
  end

  def destroy
    if current_user.id == params[:id].to_i
      flash[:error] = t('error.user.delete_self')
      redirect_to(:controller => 'customers', :action => 'index')
      return
    end

    @user = User.where('company_id = ?', current_user.company_id).find(params[:id])
    if @user.destroy
      flash[:success] = t('flash.notice.model_deleted', model: @user.name)
    else
      flash[:error] = @user.errors.full_messages.join(' ')
    end

    if @user.customer
      redirect_to edit_customer_path(@user.customer)
    else
      redirect_to root_path
    end
  end

  def update_seen_news
    if request.xhr?
      @user = current_user
      unless @user.nil?
        @user.seen_news_id = params[:id]
        @user.save
      end
    end
    render :nothing => true
  end

  def avatar
    @user = User.find(params[:id])
    unless @user.avatar?
      render :nothing => true
      return
    end
    if params[:large]
      send_file @user.avatar_large_path, :filename => 'avatar', :type => 'image/jpeg', :disposition => 'inline'
    else
      send_file @user.avatar_path, :filename => 'avatar', :type => 'image/jpeg', :disposition => 'inline'
    end
  end

  def auto_complete_for_project_name
    text = params[:term]
    if text.blank?
      return render :nothing => true
    end

    @projects = current_user.company.projects.where('lower(name) like ?', "%#{ text }%")

    if params[:user_id]
      user = User.find_by(:id => params[:user_id])
      @projects = @projects - user.projects if user
    end

    render :json => @projects.collect { |project| { value: project.name, id: project.id, status_completed: project.complete? } }.to_json
  end

  def project
    @user = current_user.company.users.active.find(params[:id])
    project = current_user.company.projects.find(params[:project_id])
    ProjectPermission.create(:user => @user, :company => @user.company, :project => project)

    render(:partial => 'project', :locals => {:project => project, :user_edit => true})
  end

  def auto_complete_for_user_name
    if (term = params[:term]).present?
      # the next line searches for names starting with given text OR surname (space started) starting with text of the active users
      @users = current_user.company.users.active.search_by_name(term).limit(50)

      if params[:project_id]
        project = Project.find_by(:id => params[:project_id])
        @users = @users - project.users if project
      end

      render :json => @users.collect { |user| {:value => user.to_s, :id => user.id} }.to_json
    else
      render :nothing => true
    end
  end

  private

  def protected_area
    @user = User.where('company_id = ?', current_user.company_id).find_by(:id => params[:id]) if params[:id]

    if Setting.contact_creation_allowed
      unless current_user.admin? or current_user.edit_clients? or current_user == @user
        flash[:error] = t('flash.alert.admin_permission_needed')
        redirect_to edit_user_path(current_user)
        return false
      end
    else
      unless current_user == @user
        redirect_to edit_user_path(current_user), alert: t('flash.alert.access_denied')
        return false
      end
    end
    true
  end

  def user_create_params
    params.fetch(:user, {}).permit :name, :username, :password, :customer_id,
                                   :set_custom_attribute_values => [:custom_attribute_id, :value, :choice_id]
  end

  def user_update_params
    params.require(:user).permit :name, :username, :password, :customer_id, :avatar, :locale, :time_zone, :receive_notifications,
                                 :receive_own_notifications, :auto_add_to_customer_tasks, :active, :comment_private_by_default, :time_format, :date_format,
                                 :option_tracktime, :option_avatars, :set_custom_attribute_values => [:custom_attribute_id, :value, :choice_id],
                                 customer_attributes: [:id, :name]
  end

  def user_access_params
    params.require(:user).permit :admin, :create_projects, :read_clients, :create_clients, :edit_clients,
                                 :can_approve_work_logs, :use_resources, :access_level_id
  end

  def work_plan_params
    params.require(:user).require(:work_plan_attributes).permit :monday, :tuesday, :wednesday, :thursday, :friday,
                                                                :saturday, :sunday
  end

end
