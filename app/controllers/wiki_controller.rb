class WikiController < ApplicationController

  def show

    name = params[:id] || 'Frontpage'

    @page = WikiPage.find(:first, :conditions => ["company_id = ? AND name = ?", session[:user].company_id, name])
    if @page.nil?
      @page = WikiPage.new
      @page.company_id = session[:user].company_id
      @page.name = name
      @page.project_id = nil
    end

  end

  def create
    @page = WikiPage.find(:first, :conditions => ["company_id = ? AND name = ?", session[:user].company_id, params[:id]])

    if @page.nil?
      @page = WikiPage.new
      @page.company_id = session[:user].company_id
      @page.name = params[:id]
      @page.project_id = nil
      @page.save
    end

    @rev = WikiRevision.new
    @rev.wiki_page = @page
    @rev.user = session[:user]
    @rev.body = params[:body]
    @rev.save

    redirect_to :action => 'show', :id => @page.name
  end

  def edit
    @page = WikiPage.find(:first, :conditions => ["company_id = ? AND name = ?", session[:user].company_id, params[:id]])
  end

  def cancel
    redirect_to :action => 'show', :id => params[:id]
  end

end
