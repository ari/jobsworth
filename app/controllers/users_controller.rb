# encoding: UTF-8
class UsersController < ApplicationController
  before_filter :protected_area, :except=>[:update_seen_news, :avatar, :auto_complete_for_project_name, :auto_complete_for_user_name]

  def index
    @users = User.where("users.company_id = ?", current_user.company_id)
                 .includes(:project_permissions => {:project => :customer})
                 .order("users.name")
                 .paginate(:page => params[:page], :per_page => 100)
  end

  def new
    @user = User.new(params[:user])
    @user.company_id = current_user.company_id
    @user.customer_id = current_user.customer_id if @user.customer_id.blank?
    @user.time_zone = current_user.time_zone
    @user.create_projects = 0
    @user.option_tracktime = 0
    @user.build_work_plan

    render :layout => 'basic'
  end

  def create
    @user = User.new(params[:user])
    @user.company_id = current_user.company_id
    @user.email = params[:email]

    if @user.errors.size > 0
      flash[:error] = @user.errors.full_messages.join(". ")
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

      flash[:success] = _('User was successfully created. Remember to give this user access to needed projects.')

      if params[:send_welcome_email]
        begin
          Signup::account_created(@user, current_user, params['welcome_message']).deliver
        rescue
          flash[:error] ||= ""
          flash[:error] += ("<br/>" + _("Error sending creation email. Account still created.")).html_safe
        end
      end

      redirect_to edit_user_path(@user)
    else
      flash[:error] = @user.errors.full_messages.join(". ")
      render :action => 'new'
    end
  end

  def edit
  end

  def access
    if request.put?
      if current_user.admin?
        flash[:success] = _('Access control was successfully updated.')
        @user.set_access_control_attributes(params[:user])
        @user.save!
      end
    end

    if !current_user.admin?
      flash[:error] = _('You cannot change the access control.')
      redirect_to edit_user_path(@user)
    end
  end

  def emails
  end

  def tasks
    @user_recent_work_logs = @user.work_logs.order(:started_at).reverse_order.includes(:task).limit(10)
  end

  def filters
    @private_filters = @user.private_task_filters.order("task_filters.name")
    @shared_filters = @user.shared_task_filters.order("task_filters.name")
  end

  def projects
  end

  def workplan
    if request.put?
      if @user.work_plan.update_attributes(params[:user][:work_plan_attributes])
        flash[:success] = _('Work plan was successfully updated.')
      else
        flash[:error] = @user.work_plan.errors.full_messages.join(', ')
      end
    end
  end

  def update
    @user = User.where("company_id = ?", current_user.company_id).find(params[:id])

    if @user.update_attributes(params[:user].except(:admin))
      flash[:success] = _('User was successfully updated.')
      redirect_to edit_user_path(@user)
    else
      flash[:error] = @user.errors.full_messages.join(". ")
      render :action => 'edit', :layout => "basic"
    end
  end

  def destroy
    if current_user.id == params[:id].to_i
      flash[:error] = _("You can't delete yourself.")
      redirect_to(:controller => "customers", :action => 'index')
      return
    end

    @user = User.where("company_id = ?", current_user.company_id).find(params[:id])
    if @user.destroy
      flash[:success] = "Successfully deleted #{@user.name}"
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
      send_file @user.avatar_large_path, :filename => "avatar", :type => 'image/jpeg', :disposition => 'inline'
    else
      send_file @user.avatar_path, :filename => "avatar", :type => 'image/jpeg', :disposition => 'inline'
    end
  end

  def auto_complete_for_project_name
    text = params[:term]
    if text.blank?
      return render :nothing => true
    end

    @projects = current_user.company.projects.where("lower(name) like ?", "%#{ text }%")

    if params[:user_id]
      user = User.find_by_id(params[:user_id])
      @projects = @projects - user.projects if user
    end

    render :json => @projects.collect{|project| {:value => project.name, :id=> project.id} }.to_json
  end

  def project
    @user = current_user.company.users.active.find(params[:id])

    project = current_user.company.projects.find(params[:project_id])

    ProjectPermission.create(:user => @user, :company => @user.company, :project => project)

    render(:partial => "project", :locals => { :project => project, :user_edit => true })
  end

  def auto_complete_for_user_name
    if (term = params[:term]).present?
      # the next line searches for names starting with given text OR surname (space started) starting with text of the active users
      @users = current_user.company.users.active.search_by_name(term).limit(50)

      if params[:project_id]
        project = Project.find_by_id(params[:project_id])
        @users = @users - project.users if project
      end

      render :json=> @users.collect{|user| {:value => user.to_s, :id=> user.id} }.to_json
    else
      render :nothing=> true
    end
  end

private
  def protected_area
    @user = User.where("company_id = ?", current_user.company_id).find_by_id(params[:id]) if params[:id]
    unless current_user.admin? or current_user.edit_clients? or current_user == @user
      flash[:error] = _("Only admins can edit users.")
      redirect_to edit_user_path(current_user)
      return false
    end
    true
  end

end
