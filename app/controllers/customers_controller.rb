# encoding: UTF-8
# Handle CRUD dealing with Customers

class CustomersController < ApplicationController
  before_filter :authorize_user_can_create_customers, :only => [:new, :create]
  before_filter :authorize_user_can_edit_customers,   :only => [:edit, :update, :destroy]
  before_filter :authorize_user_can_read_customers,   :only => [:show]

  def show
    @customer = Customer.from_company(current_user.company_id).find(params[:id])
  end

  def new
    @customer = current_user.company.customers.new
  end

  def create
    @customer         = Customer.new(params[:customer])
    @customer.company = current_user.company

    if @customer.save
      flash['notice'] = _('Customer was successfully created.')
      redirect_to root_path
    else
      render :new
    end
  end

  def edit
    @customer = Customer.from_company(current_user.company_id).where(:id => params[:id]).includes(:projects).first
  end

  def update
    @customer = Customer.from_company(current_user.company_id).find(params[:id])

    if @customer.update_attributes(params[:customer])
      flash['notice'] = _('Customer was successfully updated.')
      redirect_to :action => :edit, :id => @customer.id
    else
      render :edit
    end
  end  

  def destroy
    @customer = Customer.from_company(current_user.company_id).find(params[:id])

    if @customer.has_projects?
      flash['notice'] = 
        _("Please delete all projects for #{@customer.name} before deleting it.")

    #TODO: What the ... ?
    elsif @customer.name == current_user.company.name
      flash['notice'] = _("You can't delete your own company.")

    else
      flash['notice'] = _("Customer was successfully deleted.")
      @customer.destroy
    end

    redirect_to root_path
  end

  def search
    search_criteria = params[:term].strip

    @customers = []
    @users = []
    unless search_criteria.blank?
      @customers = Customer.search(current_user.company, [search_criteria])
      @users = User.search(current_user.company, [search_criteria])
      # add any missing customers to the list
      @users.each { |u| @customers << u.customer }

      @customers = @customers.flatten.uniq.compact
      @customers = @customers.sort_by { |c| c.name.downcase }
    end

    html = render_to_string :partial => "customers/search_autocomplete", :locals => {:users => @users, :customers => @customers}
    render :json=> { :success => true, :html => html }
  end

  private

  def authorize_user_can_create_customers
    deny_access unless current_user.admin? or current_user.create_clients?
  end

  def authorize_user_can_edit_customers
    deny_access unless current_user.admin? or current_user.edit_clients?
  end

  def authorize_user_can_read_customers
    deny_access unless current_user.admin? or current_user.read_clients?
  end

  def deny_access
    flash["notice"] = _("Access denied")
    redirect_from_last
  end
end
