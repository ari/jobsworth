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
      Notifications::milestone_changed(current_user, @milestone, 'created', due_date).deliver rescue nil
    else
      render :action => 'new'
    end
  end

  def edit
    @milestone = Milestone.find(params[:id], :conditions => ["company_id = ?", current_user.company_id])
    @milestone.due_at = tz.utc_to_local(@milestone.due_at) unless @milestone.due_at.nil?
  end

  def update
    @milestone = Milestone.find(params[:id], :conditions => ["company_id = ?", current_user.company_id])

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

      if(@old.due_at != @milestone.due_at || @old.name != @milestone.name || @old.description != @milestone.description )
        if( @old.name != @milestone.name)
          Notifications::milestone_changed(current_user, @milestone, 'renamed', @milestone.due_at, @old.name).deliver rescue nil
        else
          Notifications::milestone_changed(current_user, @milestone, 'updated', @milestone.due_at).deliver rescue nil
        end
      end

      flash[:notice] = _('Milestone was successfully updated.')
      redirect_to :controller => 'projects', :action => 'edit', :id => @milestone.project
    else
      render :action => 'edit'
    end
  end

  def destroy
    @milestone = Milestone.find(params[:id], :conditions => ["company_id = ?", current_user.company_id])
    Notifications::milestone_changed(current_user, @milestone, 'deleted', @milestone.due_at).deliver rescue nil
    @milestone.destroy

    redirect_from_last
  end

  def complete
    milestone = Milestone.find( params[:id], :conditions => ["project_id IN (#{current_project_ids})"])
    unless milestone.nil?
      milestone.completed_at = Time.now.utc
      milestone.save

      Notifications::milestone_changed(current_user, milestone, 'completed', milestone.due_at).deliver rescue nil
      flash[:notice] = _("%s / %s completed.", milestone.project.name, milestone.name)
    end
    
    redirect_from_last
  end

  def revert
    milestone = Milestone.find(params[:id], :conditions => ["project_id IN (#{current_project_ids})"])
    unless milestone.nil?
      milestone.completed_at = nil
      milestone.save
      Notifications::milestone_changed(current_user, milestone, 'reverted', milestone.due_at).deliver rescue nil
      flash[:notice] = _("%s / %s reverted.", milestone.project.name, milestone.name)
    end
    redirect_to :controller => 'activities', :action => 'list'
  end

  def list_completed
    @completed_milestones = Milestone.find(:all, :conditions => ["project_id = ? AND completed_at IS NOT NULL", params[:id]])
  end

  # Return a json formatted list of options to refresh the Milestone dropdown in tasks create/update page
  # TODO: use MilestonesController#list with json format instead of MilestonesController#get_milestone
  def get_milestones
    if params[:project_id].blank?
      render :text => "" and return
    end

    @milestones = Milestone.find(:all, :order => 'milestones.due_at, milestones.name', :conditions => ['company_id = ? AND project_id = ? AND completed_at IS NULL', current_user.company_id, params[:project_id]])
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
