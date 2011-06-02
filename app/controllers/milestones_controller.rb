# encoding: UTF-8
# Handle basic CRUD functionality regarding Milestones
class MilestonesController < ApplicationController
  before_filter :access_to_milestones, :except => [:new, :create, :list_completed, :get_milestones]

  def new
    @milestone = Milestone.new
    @milestone.user = current_user
    @milestone.project_id = params[:project_id]
    unless current_user.can?(@milestone.project, 'milestone')
      flash['notice'] = _ "You don't have access to milestones"
      if request.xhr?
        render :text => "You don't have access to milestones"
      else
        redirect_to "/activities/list"
      end
      return
    end
    if request.xhr?
      @popup, @disable_title = true, true
      render :action => 'new', :layout => false
      return
    end
  end

  # Ajax callback from milestone popup window to create a new milestone on submitting the form
  def create
    @milestone = Milestone.new(params[:milestone])
    unless current_user.can?(@milestone.project, 'milestone')
      flash['notice'] = _ "You don't have access to milestones"
      redirect_to "/activities/list"
      return
    end
    logger.debug "Creating new milestone #{@milestone.name}"
    set_due_at
    @milestone.company_id = current_user.company_id
    @milestone.user = current_user

    if @milestone.save
      unless request.xhr?
        flash[:notice] = _('Milestone was successfully created.')
        redirect_to :controller => 'projects', :action => 'edit', :id => @milestone.project
      else
        #bind 'ajax:success' event
        #return json to provide refreshMilestones parameters
        render :json => {:project_id => @milestone.project_id, :milestone_id => @milestone.id, :status => "success"}
      end
    else
      if request.xhr?
        render :action => 'new.html.erb', :layout=>false
      else
        render :action => 'new'
      end
    end
  end

  def edit
    @milestone.due_at = tz.utc_to_local(@milestone.due_at) unless @milestone.due_at.nil?
  end

  def update
    @milestone.attributes = params[:milestone]
    set_due_at
    if @milestone.save
      flash[:notice] = _('Milestone was successfully updated.')
      redirect_to :controller => 'projects', :action => 'edit', :id => @milestone.project
    else
      render :action => 'edit'
    end
  end

  def destroy
    @milestone.destroy
    redirect_to root_path
  end

  def complete
    @milestone.completed_at = Time.now.utc
    @milestone.save
    flash[:notice] = _("%s / %s completed.", @milestone.project.name, @milestone.name)
    redirect_from_last
  end

  def revert
    @milestone.completed_at = nil
    @milestone.save
    flash[:notice] = _("%s / %s reverted.", @milestone.project.name, @milestone.name)
    redirect_to :controller => 'activities', :action => 'list'
  end

  def list_completed
    @completed_milestones = Milestone.where("project_id = ? AND completed_at IS NOT NULL", params[:id])
  end

  # Return a json formatted list of options to refresh the Milestone dropdown in tasks create/update page
  # TODO: use MilestonesController#list with json format instead of MilestonesController#get_milestone
  def get_milestones
    if params[:project_id].blank?
      render :text => "" and return
    end

    @milestones = Milestone.order('milestones.due_at, milestones.name').where('company_id = ? AND project_id = ? AND completed_at IS NULL', current_user.company_id, params[:project_id])
    render :file => 'milestones/get_milestones.json.erb'
  end

  private

  def access_to_milestones
    @milestone = Milestone.where("company_id = ?", current_user.company_id).find(params[:id])
    unless current_user.can?(@milestone.project, 'milestone')
      flash['notice'] = _ "You don't have access to milestones"
      redirect_to "/activities/list"
      return false
    end
  end

  def set_due_at
    unless params[:milestone][:due_at].blank?
      begin
        due_date = DateTime.strptime(params[:milestone][:due_at], current_user.date_format)
        @milestone.due_at = tz.local_to_utc(due_date.to_time + 1.day - 1.minute) if due_date
      rescue
      end
    end
  end
end
