class WikiController < ApplicationController

  def show
    name = params[:id] || 'Frontpage'

    @page = WikiPage.find(:first, :conditions => ["company_id = ? AND name = ?", current_user.company_id, name])
    if @page.nil?
      @page = WikiPage.new
      @page.company_id = current_user.company_id
      @page.name = name
      @page.project_id = nil
      render :action => 'edit', :id => name
    end

  end

  def create
    @page = WikiPage.find(:first, :conditions => ["company_id = ? AND name = ?", current_user.company_id, params[:id]])

    if @page.nil?
      @page = WikiPage.new
      @page.company_id = current_user.company_id
      @page.name = params[:id]
      @page.project_id = nil
    end
    @page.unlock
    @page.save

    @rev = WikiRevision.new
    @rev.wiki_page = @page
    @rev.user = current_user
    @rev.body = params[:body]
    @rev.save

    redirect_to :action => 'show', :id => @page.name
  end

  def edit
    @page = WikiPage.find(:first, :conditions => ["company_id = ? AND name = ?", current_user.company_id, params[:id]])
    if @page.nil?
      @page = WikiPage.new
      @page.company_id = current_user.company_id
      @page.name = params[:id]
      @page.project_id = nil
    end

    unless @page.new_record?
      @page.lock(Time.now.utc, current_user.id)
      @page.save
    end
  end

  def cancel
    @page = WikiPage.find(:first, :conditions => ["company_id = ? AND name = ?", current_user.company_id, params[:id]])
    if @page
      @page.unlock
      @page.save
    end

    redirect_to :action => 'show', :id => params[:id]

  end

  def cancel_create
    redirect_from_last
  end

  def versions
    @page = WikiPage.find(:first, :conditions => ["company_id = ? AND name = ?", current_user.company_id, params[:id]] )
  end

end
