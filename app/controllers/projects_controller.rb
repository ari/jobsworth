# Handle Projects for a company, including permissions
class ProjectsController < ApplicationController

  cache_sweeper :project_sweeper, :only => [ :create, :edit, :update, :destroy, :ajax_remove_permission, :ajax_add_permission ]

  def new
    unless current_user.create_projects?
      flash['notice'] = _"You're not allowed to create new projects. Have your admin give you access."
      redirect_from_last
      return
    end
    
    @project = Project.new
  end

  def create
    unless current_user.create_projects?
      flash['notice'] = _"You're not allowed to create new projects. Have your admin give you access."
      redirect_from_last
      return
    end

    @project = Project.new(params[:project])
    @project.owner = current_user
    @project.company_id = current_user.company_id

    if @project.save
      if params[:copy_project].to_i > 0
        project = current_user.all_projects.find(params[:copy_project])
        project.project_permissions.each do |perm|
          p = perm.clone
          p.project_id = @project.id
          p.save

          if p.user_id == current_user.id
            @project_permission = p
          end
        
        end
      end 
        
      @project_permission ||= ProjectPermission.new

      @project_permission.user_id = current_user.id
      @project_permission.project_id = @project.id
      @project_permission.company_id = current_user.company_id
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
      render :action => 'new'
    end
  end

  def create_shortlist_ajax
    if params[:project].nil? || params[:project][:name].nil? || params[:project][:name].empty?
      render :nothing => true
      return
    end
    @project = Project.new(params[:project])
    if session[:filter_customer_short].to_i > 0
      @project.customer_id = session[:filter_customer_short].to_i
    elsif session[:filter_project_short].to_i > 0
      proj = Project.find(:first, :conditions => ["id = ? AND company_id = ?", session[:filter_project_short], current_user.company_id])
      @project.customer_id = proj.customer_id
    elsif session[:filter_milestone_short].to_i > 0
      proj = Milestone.find(:first, :conditions => ["id = ? AND company_id = ?", session[:filter_milestone_short], current_user.company_id]).project
      @project.customer_id = proj.customer_id
    elsif
      render :nothing => true
      return
    end

    @project.owner = current_user
    @project.company_id = current_user.company_id

    if @project.save
      @project_permission = ProjectPermission.new
      @project_permission.user_id = current_user.id
      @project_permission.project_id = @project.id
      @project_permission.company_id = current_user.company_id
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

      session[:filter_customer_short] = "0"
      session[:filter_milestone_short] = "0"
      session[:filter_project_short] = @project.id.to_s

      render :update do |page|
        page.redirect_to :controller => 'tasks', :action => 'shortlist'
      end

      return
    end

    render :nothing => true
  end

  def edit
    @project = current_user.projects.find(params[:id])
    if @project.nil?
      redirect_to :controller => 'activities', :action => 'list'
      return false
    end
    @users = User.find(:all, :conditions => ["company_id = ?", current_user.company_id], :order => "users.name")
  end

  def ajax_remove_permission
    permission = ProjectPermission.find(:first, :conditions => ["user_id = ? AND project_id = ? AND company_id = ?", params[:user_id], params[:id], current_user.company_id])

    if params[:perm].nil?
      permission.destroy
    else
      permission.remove(params[:perm])
      permission.save
    end

    if params[:user_edit]
      @user = current_user.company.users.find(params[:user_id])
      render :partial => "users/project_permissions"
    else 
      @project = current_user.projects.find(params[:id])
      @users = Company.find(current_user.company_id).users.find(:all, :order => "users.name")
      render :partial => "permission_list"
    end 
  end

  def ajax_add_permission
    user = User.find(params[:user_id], :conditions => ["company_id = ?", current_user.company_id])

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

    if @project && user && ProjectPermission.count(:conditions => ["user_id = ? AND project_id = ?", user.id, @project.id]) == 0
      permission = ProjectPermission.new
      permission.user_id = user.id
      permission.project_id = @project.id
      permission.company_id = current_user.company_id
      permission.can_comment = 1
      permission.can_work = 1
      permission.can_close = 1
      permission.save
    else
      permission = ProjectPermission.find(:first, :conditions => ["user_id = ? AND project_id = ? AND company_id = ?", params[:user_id], params[:id], current_user.company_id])
      permission.set(params[:perm])
      permission.save
    end

    if params[:user_edit] && current_user.admin?
      @user = current_user.company.users.find(params[:user_id])
      render :partial => "users/project_permissions"
    else 
      @users = Company.find(current_user.company_id).users.find(:all, :order => "users.name")
      render :partial => "permission_list"
    end 
  end

  def update
    @project = current_user.projects.find(params[:id])
    old_client = @project.customer_id
    old_name = @project.name

    if @project.update_attributes(params[:project])
      # Need to update forum names?
      forums = Forum.find(:all, :conditions => ["project_id = ?", params[:id]])
      if(forums.size > 0 and (@project.name != old_name))

        # Regexp to match any forum named after our project
        forum_name = Regexp.new("\\b#{old_name}\\b")

        # Check each forum object and test against the regexp
        forums.each do |forum|
          if (forum_name.match(forum.name))
            # They have a forum named after the project, so
            # replace the forum name with the new project name
            forum.name.gsub!(forum_name,@project.name)
            forum.save
          end
        end
      end

      # Need to update work-sheet entries?
      if @project.customer_id != old_client
        WorkLog.update_all("customer_id = #{@project.customer_id}", "project_id = #{@project.id} AND customer_id != #{@project.customer_id}")
      end

      flash['notice'] = _('Project was successfully updated.')
      redirect_from_last
    else
      render :action => 'edit'
    end
  end

  def destroy
    @project = current_user.projects.find(params[:id])
    @project.pages.destroy_all
    @project.sheets.destroy_all
    @project.tasks.destroy_all
    @project.work_logs.destroy_all
    @project.milestones.destroy_all
    @project.project_permissions.destroy_all
    @project.project_files.each { |p|
      p.destroy
    }

    if session[:filter_project].to_i == @project.id
      session[:filter_project] = nil
    end

    @project.destroy
    flash['notice'] = _('Project was deleted.')
    redirect_from_last
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
    project = current_user.completed_projects.find(params[:id])
    unless project.nil?
      project.completed_at = nil
      project.save
      flash[:notice] = _("%s reverted.", project.name)
    end
    redirect_to :controller => 'activities', :action => 'list'
  end

  def list_completed
    @completed_projects = current_user.completed_projects.find(:all, :conditions => ["completed_at IS NOT NULL"], :order => "completed_at DESC")
  end

  def list
    @projects = current_user.projects.find(:all, :order => 't1_r2, projects.name', :include => [ :customer, :milestones]);
    @completed_projects = current_user.completed_projects.find(:all)
  end
  
end
