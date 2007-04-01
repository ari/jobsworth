class PagesController < ApplicationController

  def show
    @page = Page.find(@params[:id], :conditions => ["company_id = ?", session[:user].company.id] )
  end

  def new
    @page = Page.new
  end

  def create
    @page = Page.new(@params[:page])

    @page.user = session[:user]
    @page.company = session[:user].company

    if @page.save

      worklog = WorkLog.new
      worklog.user = session[:user]
      worklog.project = @page.project
      worklog.company = @page.project.company
      worklog.customer = @page.project.customer
      worklog.body = "#{@page.name}"
      worklog.task_id = 0
      worklog.started_at = Time.now.utc
      worklog.duration = 0
      worklog.log_type = WorkLog::PAGE_CREATED
      worklog.body = "- #{@page.name} Created"
      worklog.save

      flash['notice'] = 'Page was successfully created.'
      redirect_to :action => 'show', :id => @page.id
    else
      render_action 'new'
    end
  end

  def edit
    @page = Page.find(@params[:id], :conditions => ["company_id = ?", session[:user].company.id] )
  end

  def update
    @page = Page.find(@params[:id], :conditions => ["company_id = ?", session[:user].company.id] )

    old_name = @page.name
    old_body = @page.body
    old_project = @page.project_id

    if @page.update_attributes(@params[:page])

      worklog = WorkLog.new
      worklog.user = session[:user]
      worklog.project = @page.project
      worklog.company = @page.project.company
      worklog.customer = @page.project.customer
      worklog.body = "#{@page.name}"
      worklog.task_id = 0
      worklog.started_at = Time.now.utc
      worklog.duration = 0
      worklog.log_type = WorkLog::PAGE_MODIFIED
      worklog.body = ""
      worklog.body << "- #{old_name} -> #{@page.name}\n" if old_name != @page.name
      worklog.body << "- #{@page.name} Modified\n" if old_body != @page.body
      worklog.save

      flash['notice'] = 'Page was successfully updated.'
      redirect_to :action => 'show', :id => @page
    else
      render_action 'edit'
    end
  end

  def destroy
    @page = Page.find(@params[:id], :conditions => ["company_id = ?", session[:user].company.id] )

    worklog = WorkLog.new
    worklog.user = session[:user]
    worklog.project = @page.project
    worklog.company = @page.project.company
    worklog.customer = @page.project.customer
    worklog.body = "#{@page.name}"
    worklog.task_id = 0
    worklog.started_at = Time.now.utc
    worklog.duration = 0
    worklog.log_type = WorkLog::PAGE_DELETED
    worklog.body = "- #{@page.name} Deleted"
    worklog.save

    @page.destroy
    redirect_to :controller => 'tasks', :action => 'list'
  end

end
