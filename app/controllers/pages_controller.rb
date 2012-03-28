# encoding: UTF-8
# Simple Page/Notes system, will grow into a full Wiki once I get the time..
class PagesController < ApplicationController
  def show
    @page = Page.where("company_id = ?", current_user.company_id).find(params[:id])
  end

  def new
    @page = Page.new(params[:page])
  end

  def create
    @page = Page.new(params[:page])

    @page.user = current_user
    @page.company = current_user.company
    if @page.save
      flash[:success] = _('Note was successfully created.')
      redirect_to :action => 'show', :id => @page.id
    else
      @page.valid?
      render :action => 'new'
    end
  end

  def edit
    @page = Page.where("company_id = ?", current_user.company_id).find(params[:id])
  end

  def update
    @page = Page.where("company_id = ?", current_user.company_id).find(params[:id])

    if @page.update_attributes(params[:page])
      flash[:success] = _('Note was successfully updated.')
      redirect_to :action => 'show', :id => @page
    else
      @page.valid?
      render :action => 'edit'
    end
  end

  def destroy
    @page = Page.where("company_id = ?", current_user.company_id).find(params[:id])
    @page.destroy
    redirect_to tasks_path
  end

  # Renders a list of possible notable targets for a page
  def target_list
    @matches = []
    str = [ params[:term] ]

    @matches += User.search(current_user.company, str)
    @matches += Customer.search(current_user.company, str)
    @matches += current_user.all_projects.where(Search.search_conditions_for(str))
    render :json=> @matches.collect{|match| {:value => "#{match.class.name} : #{match.to_s}", :id=> match.id, :type=>match.class.name, :category=> "#{match.class.name}"} }.to_json

  end

  def snippet
    snippet = current_user.company.pages.snippets.find(params[:id])
    render :text=> snippet.body
  end
end
