# encoding: UTF-8
# Handle basic CRUD functionality regarding Milestones
class MilestonesController < ApplicationController
  def new
    @milestone = Milestone.new
    @milestone.user = current_user
    @milestone.project_id = params[:project_id]
  end

  def quick_new
    self.new
    @popup, @disable_title = true, true
    render :action => 'new', :layout => false
  end

  # Ajax callback from milestone popup window to create a new milestone on submitting the form
  def create
    params_milestone = params[:milestone]

    @milestone = Milestone.new(params[:milestone])
    logger.debug "Creating new milestone #{@milestone.name}"
    due_date = nil
    if !params[:milestone][:due_at].nil? && params[:milestone][:due_at].length > 0
      begin
        due_date = DateTime.strptime( params[:milestone][:due_at], current_user.date_format )
      rescue
        due_date = nil
      end
      @milestone.due_at = tz.local_to_utc(due_date.to_time + 1.day - 1.minute) if due_date
    end

    @milestone.company_id = current_user.company_id

    if @milestone.save
      unless request.xhr?
        flash[:notice] = _('Milestone was successfully created.')
        redirect_to :controller => 'projects', :action => 'edit', :id => @milestone.project
      else
        #bind 'ajax:success' event
        #return json to provide refreshMilestones parameters
        render :json => {:project_id => @milestone.project_id, :milestone_id => @milestone.id}
      end
    else
      render :action => 'new'
    end
  end

  def edit
    @milestone = Milestone.where("company_id = ?", current_user.company_id).find(params[:id])
    @milestone.due_at = tz.utc_to_local(@milestone.due_at) unless @milestone.due_at.nil?
  end

  def update
    @milestone = Milestone.where("company_id = ?", current_user.company_id).find(params[:id])

    @old = @milestone.clone

    @milestone.attributes = params[:milestone]
    due_date = nil
    if !params[:milestone][:due_at].nil? && params[:milestone][:due_at].length > 0
      begin
        due_date = DateTime.strptime( params[:milestone][:due_at], current_user.date_format )
        @milestone.due_at = tz.local_to_utc(due_date.to_time + 1.day - 1.minute)
      rescue Exception => e
        @milestone.due_at= @old.due_at
      end
    end
    if @milestone.save

   

      flash[:notice] = _('Milestone was successfully updated.')
      redirect_to :controller => 'projects', :action => 'edit', :id => @milestone.project
    else
      render :action => 'edit'
    end
  end

  def destroy
    @milestone = Milestone.where("company_id = ?", current_user.company_id).find(params[:id])
    @milestone.destroy

    redirect_from_last
  end

  def complete
    milestone = Milestone.where("project_id IN (?)", current_project_ids).find(params[:id])
    unless milestone.nil?
      milestone.completed_at = Time.now.utc
      milestone.save

      flash[:notice] = _("%s / %s completed.", milestone.project.name, milestone.name)
    end
    
    redirect_from_last
  end

  def revert
    milestone = Milestone.where("project_id IN (?)", current_project_ids).find(params[:id])
    unless milestone.nil?
      milestone.completed_at = nil
      milestone.save
      flash[:notice] = _("%s / %s reverted.", milestone.project.name, milestone.name)
    end
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
    @milestones = @milestones.map { |m| { :text => m.name.gsub(/"/,'\"'), :value => m.id.to_s  } }
    @milestones = @milestones.map { |m| m.to_json }
    @milestones = @milestones.join(", ")

    res = '{"options":[{"value":"0", "text":"' + _('[None]') + '"}'
    res << ", #{@milestones}" unless @milestones.nil? || @milestones.empty?
    res << '],'
    p = current_user.projects.find(params[:project_id]) rescue nil
    if p && current_user.can?(p, 'milestone')
      res << '"add_milestone_visible":"true"'
    else
      res << '"add_milestone_visible":"false"'
    end
    res << '}'

    render :text => "#{res}"
  end
end
