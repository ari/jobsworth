class CompaniesController < ApplicationController
  def index
    if session[:user].admin > 0
      list
      render_action 'list'
    end 
  end

  def list
    if session[:user].admin > 0
      @company_pages, @companies = paginate :company, :per_page => 10
    end 
  end

  def show
    if session[:user].admin > 0
      @company = Company.find(@params[:id])
    end
  end

  def new
    if session[:user].admin > 0
      @company = Company.new
    end
  end

  def edit
    if session[:user].admin > 0
      @company = Company.find(@params[:id])
    end
  end

  def update
    if session[:user].admin > 0
      @company = Company.find(@params[:id])
      if @company.update_attributes(@params[:company])
	flash['notice'] = 'Company was successfully updated.'
	redirect_to :action => 'show', :id => @company
	else
	  render_action 'edit'
	end
      end
  end

  def destroy
    if session[:user].admin > 0
      Company.find(@params[:id]).destroy
      redirect_to :action => 'list'
    end 
  end
end
