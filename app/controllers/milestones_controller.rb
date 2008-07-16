# Handle basic CRUD functionality regarding Milestones
class MilestonesController < ApplicationController

  cache_sweeper :cache_sweeper, :only => [:update, :destroy]

  def index
    list
    render :action => 'list'
  end

  def list
    @milestones = Milestone.find(:all, :conditions => ["project_id = ?", session[:project].id], :order => "due_at")
  end

  def new
    @milestone = Milestone.new
    @milestone.user = current_user
    @milestone.project_id = params[:project_id]
  end

  def quick_new
    self.new
    @popup = true
    render :action => 'new', :layout => 'popup'
  end 

  def create
    params_milestone = params[:milestone]

    @milestone = Milestone.new(params[:milestone])

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
        render :update do |page|
          page << "window.opener.refreshMilestones(#{@milestone.project_id}, #{@milestone.id});"
          page << "window.close();"
        end 
      end 
      Notifications::deliver_milestone_changed(current_user, @milestone, 'created', due_date) rescue nil
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
      due_date = DateTime.strptime( params[:milestone][:due_at], current_user.date_format )
      @milestone.due_at = tz.local_to_utc(due_date.to_time + 1.day - 1.minute)
    end
    if @milestone.save
      
      if(@old.due_at != @milestone.due_at || @old.name != @milestone.name || @old.description != @milestone.description )
        if( @old.name != @milestone.name)
          Notifications::deliver_milestone_changed(current_user, @milestone, 'renamed', @milestone.due_at, @old.name) rescue nil
        else 
          Notifications::deliver_milestone_changed(current_user, @milestone, 'updated', @milestone.due_at) rescue nil
        end 
      end 
      
      flash[:notice] = _('Milestone was successfully updated.')
      redirect_from_last
    else
      render :action => 'edit'
    end
  end

  def destroy
    @milestone = Milestone.find(params[:id], :conditions => ["company_id = ?", current_user.company_id])

    @milestone.tasks.each { |t|
      t.milestone = nil
      t.save
    }

    if session[:filter_milestone].to_i == @milestone.id
      session[:filter_milestone] = "0"
    end

    Notifications::deliver_milestone_changed(current_user, @milestone, 'deleted', @milestone.due_at) rescue nil
    @milestone.destroy

    redirect_from_last
  end

  def complete
    milestone = Milestone.find( params[:id], :conditions => ["project_id IN (#{current_project_ids})"])
    unless milestone.nil?
      milestone.completed_at = Time.now.utc
      milestone.save

      Notifications::deliver_milestone_changed(current_user, milestone, 'completed', milestone.due_at) rescue nil
      flash[:notice] = _("%s / %s completed.", milestone.project.name, milestone.name)
    end
    redirect_to :controller => 'activities', :action => 'list'
  end

  def revert
    milestone = Milestone.find(params[:id], :conditions => ["project_id IN (#{current_project_ids})"])
    unless milestone.nil?
      milestone.completed_at = nil
      milestone.save
      Notifications::deliver_milestone_changed(current_user, milestone, 'reverted', milestone.due_at) rescue nil
      flash[:notice] = _("%s / %s reverted.", milestone.project.name, milestone.name)
    end
    redirect_to :controller => 'activities', :action => 'list'
  end

  def list_completed
    @completed_milestones = Milestone.find(:all, :conditions => ["project_id = ? AND completed_at IS NOT NULL", params[:id]])
  end

end
