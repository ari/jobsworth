# Handle Projects for a company, including permissions
class ProjectsController < ApplicationController

  cache_sweeper :project_sweeper, :only => [ :create, :edit, :update, :destroy, :ajax_remove_permission, :ajax_add_permission ]

  def index
    list
    render_action 'list'
  end
  def new
    @project = Project.new
  end

  def create
    @project = Project.new(params[:project])
    @project.owner = session[:user]
    @project.company_id = session[:user].company_id


    if @project.save
      @project_permission = ProjectPermission.new
      @project_permission.user_id = session[:user].id
      @project_permission.project_id = @project.id
      @project_permission.company_id = session[:user].company_id
      @project_permission.can_comment = 1
      @project_permission.can_work = 1
      @project_permission.can_close = 1
      @project_permission.can_report = 1
      @project_permission.can_create = 1
      @project_permission.can_edit = 1
      @project_permission.can_reassign = 1
      @project_permission.can_prioritize = 1
      @project_permission.can_milestone = 1
      @project_permission.can_grant = 1
      @project_permission.save

      if @project.company.users.size == 1
        flash['notice'] = _('Project was successfully created.')
        redirect_from_last
      else
        flash['notice'] = _('Project was successfully created. Add users who need access to this project.')
        redirect_to :action => 'edit', :id => @project
      end
    else
      render_action 'new'
    end
  end

  def edit
    @project = User.find(session[:user].id).projects.find(@params[:id], :conditions => ["projects.company_id = ?", session[:user].company_id])
    if @project.nil?
      redirect_to :controller => 'activities', :action => 'list'
      return false
    end
    @users = User.find(:all, :conditions => ["company_id = ?", session[:user].company_id], :order => "users.name")
  end

  def ajax_remove_permission
    permission = ProjectPermission.find(:first, :conditions => ["user_id = ? AND project_id = ? AND company_id = ?", params[:user_id], params[:id], session[:user].company_id])

    if params[:perm].nil?
      permission.destroy
    else
      case params[:perm]
      when 'comment'    then permission.can_comment = 0
      when 'work'       then permission.can_work = 0
      when 'close'      then permission.can_close = 0
      when 'report'     then permission.can_report = 0
      when 'create'     then permission.can_create = 0
      when 'edit'       then permission.can_edit = 0
      when 'reassign'   then permission.can_reassign = 0
      when 'prioritize' then permission.can_prioritize = 0
      when 'milestone'  then permission.can_milestone = 0
      when 'grant'      then permission.can_grant = 0
      end
      permission.save
    end

    @project = User.find(session[:user].id).projects.find(params[:id])
    @users = Company.find(session[:user].company_id).users.find(:all, :order => "users.name")

    render :partial => "permission_list"
  end

  def ajax_add_permission
    user = User.find(params[:user_id], :conditions => ["company_id = ?", session[:user].company_id])


    @project = User.find(session[:user].id).projects.find(params[:id])
    if @project && user && ProjectPermission.count(["user_id = ? AND project_id = ?", user.id, @project.id]) == 0
      permission = ProjectPermission.new
      permission.user_id = user.id
      permission.project_id = @project.id
      permission.company_id = session[:user].company_id
      permission.can_comment = 1
      permission.can_work = 1
      permission.can_close = 1
      permission.save
    else
      permission = ProjectPermission.find(:first, :conditions => ["user_id = ? AND project_id = ? AND company_id = ?", params[:user_id], params[:id], session[:user].company_id])
      case params[:perm]
      when 'comment'    then permission.can_comment = 1
      when 'work'       then permission.can_work = 1
      when 'close'      then permission.can_close = 1
      when 'report'     then permission.can_report = 1
      when 'create'     then permission.can_create = 1
      when 'edit'       then permission.can_edit = 1
      when 'reassign'   then permission.can_reassign = 1
      when 'prioritize' then permission.can_prioritize = 1
      when 'milestone'  then permission.can_milestone = 1
      when 'grant'      then permission.can_grant = 1
      end
      permission.save
    end
    @users = Company.find(session[:user].company_id).users.find(:all, :order => "users.name")

    render :partial => "permission_list"
  end

  def update
    @project = User.find(session[:user].id).projects.find(@params[:id])
    if @project.update_attributes(@params[:project])
      flash['notice'] = _('Project was successfully updated.')
      redirect_to :controller => 'activities', :action => 'list'
    else
      render_action 'edit'
    end
  end

  def destroy
    @project = User.find(session[:user].id).projects.find(@params[:id])
    @project.pages.destroy_all
    @project.sheets.destroy_all
    @project.tasks.destroy_all
    @project.work_logs.destroy_all
    @project.activities.destroy_all
    @project.milestones.destroy_all
    @project.project_permissions.destroy_all
    @project.project_files.each { |p|
      p.binary.destroy if p.binary
      p.thumbnail.destroy if p.thumbnail
      p.destroy
    }

    if session[:filter_project].to_i == @project.id
      session[:filter_project] = nil
    end

    @project.destroy
    flash['notice'] = _('Project was deleted.')
    redirect_to :controller => 'activities', :action => 'list'
  end

  def select
    user = User.find(session[:user].id)
    @project = user.projects.find(@params[:id])
    if user.respond_to?(:last_project_id)
      user.last_project_id = @project.id
      user.save
    end

    session[:project] = @project
    session[:filter_milestone] = nil

    session[:user].last_milestone_id = nil if session[:user].respond_to? :last_milestone_id
    session[:user].save

    expire_fragment( %r{application/projects\.action_suffix=#{session[:user].company_id}_#{session[:user].id}} )

    redirect_to :controller => 'activities', :action => 'list'
  end

  def complete
    project = Project.find(params[:id], :conditions => ["id IN (#{current_project_ids}) AND completed_at IS NULL"])
    unless project.nil?
      project.completed_at = Time.now.utc
      project.save
      flash[:notice] = _("%s completed.", project.name )
    end
    redirect_to :controller => 'activities', :action => 'list'
  end

  def revert
    project = User.find(session[:user].id).projects.find(params[:id], :conditions => ["completed_at IS NOT NULL"])
    unless project.nil?
      project.completed_at = nil
      project.save
      flash[:notice] = _("%s reverted.", project.name)
    end
    redirect_to :controller => 'activities', :action => 'list'
  end

  def list_completed
    @completed_projects = User.find(session[:user].id).projects.find(:all, :conditions => ["completed_at IS NOT NULL"], :order => "completed_at DESC")
  end

end
