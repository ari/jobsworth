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
        redirect_to "/activities"
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
      redirect_to "/activities"
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
    redirect_to :controller => 'projects', :action => 'edit', :id => @milestone.project
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
    redirect_from_last
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
      redirect_to "/activities"
      return false
    end
  end

  def set_due_at
    unless params[:milestone][:due_at].blank?
      begin
        # if due_at is not changed in edit, it should include time part
        format = "#{current_user.date_format} #{current_user.time_format}"
        @milestone.due_at = DateTime.strptime(params[:milestone][:due_at], format).ago(tz.current_period.utc_total_offset)
      rescue
        # if due_at is changed or set the first time, it only has date part, understood as midnight at user's timezone
        format = "#{current_user.date_format}"
        @milestone.due_at = DateTime.strptime(params[:milestone][:due_at], format).ago(tz.current_period.utc_total_offset - 24*3600)
      end
    end
  end
end
