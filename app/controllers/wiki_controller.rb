# encoding: UTF-8
class WikiController < ApplicationController

  def show
    name = params[:id] || 'Frontpage'

    @page = WikiPage.where("company_id = ? AND name = ?", current_user.company_id, name).first
    if @page.nil?
      @page = WikiPage.new
      @page.company_id = current_user.company_id
      @page.name = name
      @page.project_id = nil
      render :action => 'edit', :id => name
    end

  end

  def create
    @page = WikiPage.where("company_id = ? AND name = ?", current_user.company_id, params[:id]).first

    if @page.nil?
      @page = WikiPage.new
      @page.company_id = current_user.company_id
      @page.name = params[:id]
      @page.project_id = nil
      @page.save
    end

    @rev = WikiRevision.new
    @rev.wiki_page = @page
    @rev.user = current_user
    @rev.body = params[:body]
    @rev.change = params[:change]
    @rev.save

    @page.reload
    @page.unlock

    # Create event log
    l = @page.event_logs.new
    l.company_id = @page.company_id
    l.project_id = @page.project_id
    l.user_id = current_user.id
    l.event_type = @page.revisions.size < 2 ? EventLog::WIKI_CREATED : EventLog::WIKI_MODIFIED
    l.created_at = @rev.created_at
    l.body = params[:change]
    l.save

    redirect_to :action => 'show', :id => @page.name
  end

  def edit
    @page = WikiPage.where("company_id = ? AND name = ?", current_user.company_id, params[:id]).first
    if @page.nil?
      @page = WikiPage.new
      @page.company_id = current_user.company_id
      @page.name = params[:id]
      @page.project_id = nil
    end

    unless @page.new_record?
      @page.lock(Time.now.utc, current_user.id)
    end
  end

  def cancel
    @page = WikiPage.where("company_id = ? AND name = ?", current_user.company_id, params[:id]).first
    if @page
      @page.unlock
    end

    redirect_to :action => 'show', :id => params[:id]

  end

  def cancel_create
    redirect_from_last
  end

  def versions
    @page = WikiPage.where("company_id = ? AND name = ?", current_user.company_id, params[:id]).first
  end

end
