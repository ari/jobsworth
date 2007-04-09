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
    @milestone.user = session[:user]
    @milestone.project_id = params[:project_id]
  end

  def create
    @params_milestone = @params[:milestone]

    @milestone = Milestone.new(params[:milestone])


    if !@params[:milestone][:due_at].nil? && @params[:milestone][:due_at].length > 0
      due_date = DateTime.strptime( @params[:milestone][:due_at], session[:user].date_format )
      @milestone.due_at = tz.local_to_utc(due_date.to_time + 1.day - 1.minute)
    end

    @milestone.company_id = session[:user].company_id

    if @milestone.save
      flash[:notice] = _('Milestone was successfully created.')
      redirect_from_last
    else
      render :action => 'new'
    end
  end

  def edit
    @milestone = Milestone.find(params[:id], :conditions => ["company_id = ?", session[:user].company_id])
    @milestone.due_at = tz.utc_to_local(@milestone.due_at) unless @milestone.due_at.nil?
  end

  def update
    @milestone = Milestone.find(params[:id], :conditions => ["company_id = ?", session[:user].company_id])

    @milestone.attributes = params[:milestone]
    if !@params[:milestone][:due_at].nil? && @params[:milestone][:due_at].length > 0
      due_date = DateTime.strptime( @params[:milestone][:due_at], session[:user].date_format )
      @milestone.due_at = tz.local_to_utc(due_date.to_time + 1.day - 1.minute)
    end
    if @milestone.save
      flash[:notice] = _('Milestone was successfully updated.')
      redirect_from_last
    else
      render :action => 'edit'
    end
  end

  def destroy
    @milestone = Milestone.find(params[:id], :conditions => ["company_id = ?", @session[:user].company_id])

    @milestone.tasks.each { |t|
      t.milestone = nil
      t.save
    }

    if session[:filter_milestone].to_i == @milestone.id
      session[:filter_milestone] = "0"
    end

    @milestone.destroy

    redirect_from_last
  end

  def complete
    milestone = Milestone.find( params[:id], :conditions => ["project_id IN (#{current_project_ids})"])
    unless milestone.nil?
      milestone.completed_at = Time.now.utc
      milestone.save
      flash[:notice] = _("%s / %s completed.", milestone.project.name, milestone.name)
    end
    redirect_to :controller => 'activities', :action => 'list'
  end

  def revert
    milestone = Milestone.find(params[:id], :conditions => ["project_id IN (#{current_project_ids})"])
    unless milestone.nil?
      milestone.completed_at = nil
      milestone.save
      flash[:notice] = _("%s / %s reverted.", milestone.project.name, milestone.name)
    end
    redirect_to :controller => 'activities', :action => 'list'
  end

  def list_completed
    @completed_milestones = Milestone.find(:all, :conditions => ["project_id = ? AND completed_at IS NOT NULL", params[:id]])
  end

end
