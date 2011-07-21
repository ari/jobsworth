# encoding: UTF-8
# Handle CRUD dealing with Customers, as well as upload of logos.
#
# Logo and CSS should be used when printing reports, or generating a PDF of a report.

class CustomersController < ApplicationController
  before_filter :authorize_user_can_create_customers, :only => [:new, :create]
  before_filter :authorize_user_can_edit_customers,   :only => [:edit, :update, :destroy]
  before_filter :authorize_user_can_read_customers,   :only => [:index, :show]

  def index
    @customers = paginate Customer.from_company(current_user.company_id), 
                          per_page = 100,
                          :order => 'name'
  end

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
      redirect_to customers_path
    else
      render :new
    end
  end

  def edit
    @customer = Customer.from_company(current_user.company_id).find(params[:id])
  end

  def update
    @customer = Customer.from_company(current_user.company_id).find(params[:id])

    if @customer.update_attributes(params[:customer])
      flash['notice'] = _('Customer was successfully updated.')
      redirect_to customers_path
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

    redirect_to customers_path
  end

  def search
    search_criteria = params[:search_text].strip

    unless search_criteria.blank?
      @customers = paginate Customer.from_company(current_user.company_id)
                                    .search_by_name(search_criteria),
                            per_page = 100,
                            :order => 'name'
    end

    render :index
  end

  def upload_logo
    if params['customer'].nil? || 
       params['customer']['tmp_file'].nil? || 
       !params['customer']['tmp_file'].respond_to?('original_filename')
      flash['notice'] = _('No file selected.')
      redirect_from_last
      return
    end

    unless params['customer']['tmp_file'].size > 0
      flash['notice'] = _('Empty file uploaded.')
      redirect_from_last
      return
    end

    @customer = Customer.where("company_id = ?", current_user.company_id).
                find(params['customer']['id'])

    if @customer.logo?
      @customer.logo.destroy rescue begin
        flash['notice'] = _("Permission denied while deleting old logo.")
        redirect_to customers_path
        return
      end
    end

    @customer.logo= params['customer']['tmp_file']
    @customer.save!

    flash['notice'] = _('Logo successfully uploaded.')

    if params[:company_settings]
       redirect_to :controller => 'companies', :action => 'edit', :id => current_user.company
    else
       redirect_from_last
    end
  end

  def delete_logo
    @customer = Customer.where("company_id = ?", current_user.company_id).find(params[:id])
    if !@customer.nil? && customer.logo?
      @cusomer.logo.destroy rescue begin end
    end
    redirect_from_last
  end

  # Show a clients logo
  def show_logo
    company = company_from_subdomain
    client = company.customers.find(params[:id])

    if client.logo?
      # N.B. Modern browsers don't seem to mind us not sending the mime type here,
      # so let's save an expensive call to rmagick and just send through the file
      # Tested with FF 3.5, Opera 10, Safari 4.0, IE7, Chrome 2.0
      send_file(client.logo_path, :filename => "logo", :disposition => "inline")
    else
      render :nothing => true
    end
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
