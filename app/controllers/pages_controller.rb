# Simple Page/Notes system, will grow into a full Wiki once I get the time..
class PagesController < ApplicationController

  def show
    @page = Page.find(params[:id], :conditions => ["company_id = ?", current_user.company.id] )
  end

  def new
    @page = Page.new
  end

  def create
    @page = Page.new(params[:page])

    @page.user = current_user
    @page.company = current_user.company
    if((@page.project_id.to_i > 0) && @page.save )
      worklog = WorkLog.new
      worklog.user = current_user
      worklog.project = @page.project
      worklog.company = @page.project.company
      worklog.customer = @page.project.customer
      worklog.body = "#{@page.name}"
      worklog.task_id = 0
      worklog.started_at = Time.now.utc
      worklog.duration = 0
      worklog.log_type = EventLog::PAGE_CREATED
      worklog.body = "- #{@page.name} Created"
      worklog.save

      flash['notice'] = _('Note was successfully created.')
      redirect_to :action => 'show', :id => @page.id
    else
      render :action => 'new'
    end
  end

  def edit
    @page = Page.find(params[:id], :conditions => ["company_id = ?", current_user.company.id] )
  end

  def update
    @page = Page.find(params[:id], :conditions => ["company_id = ?", current_user.company.id] )

    old_name = @page.name
    old_body = @page.body
    old_project = @page.project_id

    if @page.update_attributes(params[:page])

      worklog = WorkLog.new
      worklog.user = current_user
      worklog.project = @page.project
      worklog.company = @page.project.company
      worklog.customer = @page.project.customer
      worklog.body = "#{@page.name}"
      worklog.task_id = 0
      worklog.started_at = Time.now.utc
      worklog.duration = 0
      worklog.log_type = EventLog::PAGE_MODIFIED
      worklog.body = ""
      worklog.body << "- #{old_name} -> #{@page.name}\n" if old_name != @page.name
      worklog.body << "- #{@page.name} Modified\n" if old_body != @page.body
      worklog.save

      flash['notice'] = _('Note was successfully updated.')
      redirect_to :action => 'show', :id => @page
    else
      render :action => 'edit'
    end
  end

  def destroy
    @page = Page.find(params[:id], :conditions => ["company_id = ?", current_user.company.id] )

    worklog = WorkLog.new
    worklog.user = current_user
    worklog.project = @page.project
    worklog.company = @page.project.company
    worklog.customer = @page.project.customer
    worklog.body = "#{@page.name}"
    worklog.task_id = 0
    worklog.started_at = Time.now.utc
    worklog.duration = 0
    worklog.log_type = EventLog::PAGE_DELETED
    worklog.body = "- #{@page.name} Deleted"
    worklog.save

    @page.destroy
    redirect_to :controller => 'tasks', :action => 'list'
  end


end
