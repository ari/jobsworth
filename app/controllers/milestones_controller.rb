# encoding: UTF-8
# Handle basic CRUD functionality regarding Milestones
class MilestonesController < ApplicationController
  before_filter :access_to_milestones, :except => [:index, :new, :create, :get_milestones]

  def index
    all_project_ids = current_user.all_project_ids

    @scheduled_milestones = current_user.company.milestones.active.where(['project_id in (?)', all_project_ids]).where('due_at IS NOT NULL').order('due_at ASC')
    @unscheduled_milestones = current_user.company.milestones.active.where(['project_id in (?)', all_project_ids]).where(:due_at => nil)
  end

  def new
    @milestone = Milestone.new
    @milestone.user = current_user
    @milestone.project_id = params[:project_id]

    unless current_user.can?(@milestone.project, 'milestone')
      message = t('flash.alert.access_denied_to_model', model: Project.human_attribute_name(:milestones))

      if request.xhr?
        render text: message
      else
        redirect_to '/activities', alert: message
      end
      return
    end

    if request.xhr?
      return render 'milestones/new-dialog', :layout => false
    end
  end

  # Ajax callback from milestone popup window to create a new milestone on submitting the form
  def create
    @milestone = Milestone.new(milestone_attributes)
    unless current_user.can?(@milestone.project, 'milestone')
      flash[:error] = t('flash.alert.access_denied_to_model', model: Project.human_attribute_name(:milestones))
      redirect_to '/activities'
      return
    end
    logger.debug "Creating new milestone #{@milestone.name}"
    set_due_at
    @milestone.company_id = current_user.company_id
    @milestone.user = current_user

    if @milestone.save
      if request.xhr?
        #bind 'ajax:success' event
        #return json to provide refreshMilestones parameters
        render :json => {:project_id => @milestone.project_id, :milestone_id => @milestone.id, :status => 'success'}
      else
        flash[:success] = t('flash.notice.model_created', model: Milestone.model_name.human)
        redirect_to :controller => 'projects', :action => 'edit', :id => @milestone.project
      end
    else
      flash[:error] = @milestone.errors.full_messages.join('. ')
      if request.xhr?
        render :action => 'new.html.erb', :layout => false
      else
        render :action => 'new'
      end
    end
  end

  def edit
    if @milestone.closed?
      flash[:error] = t('flash.error.model_closed', model: Milestone.model_name.human)
      redirect_to edit_project_path(@milestone.project)
    end
  end

  def update
    if @milestone.closed?
      flash[:error] = t('flash.error.model_closed', model: Milestone.model_name.human)
      redirect_to edit_project_path(@milestone.project)
    end

    @milestone.attributes = milestone_attributes
    set_due_at
    if @milestone.save
      flash[:success] = t('flash.notice.model_updated', model: Milestone.model_name.human)
      redirect_to :controller => 'projects', :action => 'edit', :id => @milestone.project
    else
      flash[:error] = @milestone.errors.full_messages.join('. ')
      render :action => 'edit'
    end
  end

  def destroy
    @milestone.destroy
    redirect_to :controller => 'projects', :action => 'edit', :id => @milestone.project
  end

  def complete
    @milestone.completed_at = Time.now.utc
    @milestone.status_name = :closed
    @milestone.save
    flash[:success] = t('flash.notice.completed', model: @milestone.to_s)
    redirect_to edit_project_path(@milestone.project)
  end

  def revert
    @milestone.completed_at = nil
    @milestone.status_name = :open
    @milestone.save
    flash[:success] = t('flash.notice.model_reverted', model: @milestone.to_s)
    redirect_to edit_milestone_path(@milestone)
  end

  # Return a json formatted list of options to refresh the Milestone dropdown in tasks create/update page
  # TODO: use MilestonesController#list with json format instead of MilestonesController#get_milestone
  def get_milestones
    if params[:project_id].blank?
      render :text => '' and return
    end

    @milestones = Milestone.can_add_task.order('milestones.due_at, milestones.name').where('company_id = ? AND project_id = ?', current_user.company_id, params[:project_id])
    render :file => 'milestones/get_milestones.json.erb'
  end

  private

  def access_to_milestones
    @milestone = Milestone.where('company_id = ?', current_user.company_id).find(params[:id])
    unless current_user.can?(@milestone.project, 'milestone')
      flash[:error] = t('flash.alert.access_denied_to_model', model: Project.human_attribute_name(:milestones))
      redirect_to '/activities'
      return false
    end
  end

  def set_due_at
    unless params[:milestone][:due_at].blank?
      begin
        # Only care about the date part, parse the input date string into DateTime in UTC.
        # Later, the date part will be converted from DateTime to string display in UTC, so that it doesn't change.
        format = "#{current_user.date_format}"
        @milestone.due_at = DateTime.strptime(params[:milestone][:due_at], format).ago(-12.hours)
      rescue
      end
    end
  end

  def milestone_attributes
    params.require(:milestone).permit :name, :due_at, :description, :project_id, :start_at, :status
  end
end
