# Simple Page/Notes system, will grow into a full Wiki once I get the time..
class PagesController < ApplicationController
  def show
    @page = Page.find(params[:id], :conditions => ["company_id = ?", current_user.company.id] )
  end

  def new
    @page = Page.new(params[:page])
  end

  def create
    @page = Page.new(params[:page])

    @page.user = current_user
    @page.company = current_user.company
    if @page.save
      flash['notice'] = _('Note was successfully created.')
      redirect_to :action => 'show', :id => @page.id
    else
      @page.valid?
      render :action => 'new'
    end
  end

  def edit
    @page = Page.find(params[:id], :conditions => ["company_id = ?", current_user.company.id] )
  end

  def update
    @page = Page.find(params[:id], :conditions => ["company_id = ?", current_user.company.id] )

    if @page.update_attributes(params[:page])
      flash['notice'] = _('Note was successfully updated.')
      redirect_to :action => 'show', :id => @page
    else
      @page.valid?
      render :action => 'edit'
    end
  end

  def destroy
    @page = Page.find(params[:id], :conditions => ["company_id = ?", current_user.company.id] )
    @page.destroy
    redirect_to :controller => 'tasks', :action => 'list'
  end

  # Renders a list of possible notable targets for a page
  def target_list
    @matches = []
    str = [ params[:term] ]

    @matches += User.search(current_user.company, str)
    @matches += Customer.search(current_user.company, str)
    @matches += current_user.all_projects.find(:all,
                              :conditions => Search.search_conditions_for(str))
    render :json=> @matches.collect{|match| {:value => "#{match.class.name} : #{match.to_s}", :id=> match.id, :type=>match.class.name} }.to_json

  end
end
