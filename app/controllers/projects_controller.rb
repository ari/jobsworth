# encoding: UTF-8
# Handle Projects for a company, including permissions

class ProjectsController < ApplicationController
  before_filter :authorize_user_is_admin, :except => [:index, :new, :create, :list_completed]
  before_filter :authorize_user_can_create_projects, :only => [:new, :create]
  before_filter :scope_projects, :except => [:new, :create]

  def index
    @projects = @project_relation
                .in_progress.order('customer_id')
                .includes(:customer, :milestones)
                .paginate(:page => params[:page], :per_page => 100)

    @completed_projects = @project_relation.completed
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(params[:project])
    @project.company_id = current_user.company_id

    if @project.save
      create_project_permissions_for(@project)
      check_if_project_has_users(@project)
    else
      render :new
    end
  end

  def edit
    @project = @project_relation.find(params[:id])

    if @project.nil?
      redirect_to :controller => 'activities', :action => 'index'
      return false
    end

    @users = User.where("company_id = ?", current_user.company_id).order("users.name")
  end

  def ajax_remove_permission
    permission = ProjectPermission.where("user_id = ? AND project_id = ? AND company_id = ?", params[:user_id], params[:id], current_user.company_id).first

    if params[:perm].nil?
      permission.destroy
    else
      permission.remove(params[:perm])
      permission.save
    end

    if params[:user_edit]
      @user = current_user.company.users.find(params[:user_id])
      render :partial => "/users/project_permissions"
    else
      @project = current_user.projects.find(params[:id])
      @users = Company.find(current_user.company_id).users.order("users.name")
      render :partial => "permission_list"
    end
  end

  def ajax_add_permission
    user = User.active.where("company_id = ?", current_user.company_id).find(params[:user_id])

    begin
      if current_user.admin?
        @project = current_user.company.projects.find(params[:id])
      else
        @project = current_user.projects.find(params[:id])
      end
    rescue
      render :update do |page|
        page.visual_effect(:highlight, "user-#{params[:user_id]}", :duration => 1.0, :startcolor => "'#ff9999'")
      end
      return
    end

    if @project && user && ProjectPermission.where("user_id = ? AND project_id = ?", user.id, @project.id).empty?
      permission = ProjectPermission.new
      permission.user_id = user.id
      permission.project_id = @project.id
      permission.company_id = current_user.company_id
      permission.can_comment = 1
      permission.can_work = 1
      permission.can_close = 1
      permission.save
    else
      permission = ProjectPermission.where("user_id = ? AND project_id = ? AND company_id = ?", params[:user_id], params[:id], current_user.company_id).first
      permission.set(params[:perm])
      permission.save
    end

    if params[:user_edit] && current_user.admin?
      @user = current_user.company.users.find(params[:user_id])
      render :partial => "users/project_permissions"
    else
      @users = Company.find(current_user.company_id).users.order("users.name")
      render :partial => "permission_list"
    end
  end

  def update
    @project = @project_relation.in_progress.find(params[:id])
    old_client = @project.customer_id
    old_name = @project.name

    if @project.update_attributes(params[:project])
      # Need to update work-sheet entries?
      if @project.customer_id != old_client
        WorkLog.update_all("customer_id = #{@project.customer_id}", "project_id = #{@project.id} AND customer_id != #{@project.customer_id}")
      end

      flash['notice'] = _('Project was successfully updated.')
      redirect_to :action=> "index"
    else
      render :action => 'edit'
    end
  end

  def destroy
    project=@project_relation.find(params[:id])
    if project.destroy
      flash['notice'] = _('Project was deleted.')
    else
      flash['notice'] = project.errors[:base].join(', ')
    end

    redirect_to :controller => 'projects', :action => 'index'
  end

  def complete
    project = @project_relation.in_progress.find(params[:id])
    unless project.nil?
      project.completed_at = Time.now.utc
      project.save
      flash[:notice] = _("%s completed.", project.name )
    end
    redirect_to :controller => 'activities', :action => 'index'
  end

  def revert
    project = @project_relation.completed.find(params[:id])
    unless project.nil?
      project.completed_at = nil
      project.save
      flash[:notice] = _("%s reverted.", project.name)
    end
    redirect_to :controller => 'activities', :action => 'index'
  end

  def list_completed
    @completed_projects = @project_relation.completed.order("completed_at DESC")
  end

  private

  def authorize_user_can_create_projects
    msg = "You're not allowed to create new projects. Have your admin give you access."
    deny_access(msg) unless current_user.create_projects?
  end

  def create_project_permissions_for(project)
    if params[:copy_project].to_i > 0
      project_to_copy = current_user.all_projects.find(params[:copy_project])
      project.copy_permissions_from(project_to_copy, current_user)
    else
      project.create_default_permissions_for(current_user)
    end
  end

  def check_if_project_has_users(project)
    if project.has_users?
      flash['notice'] = _('Project was successfully created.')
      redirect_to projects_path
    else
      flash['notice'] = 
        _('Project was successfully created. Add users who need access to this project.')
      redirect_to edit_project_path(project)
    end
  end

  def deny_access(msg)
    flash['notice'] = _(msg)
    redirect_from_last
  end

  def scope_projects
    @project_relation = current_user.get_projects
  end
end
