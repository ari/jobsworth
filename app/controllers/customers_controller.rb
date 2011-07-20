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

  def search
    session[:client_name_filter] = params[:search_text].strip

    if !session[:client_name_filter].blank?
      filter = []
      filter << session[:client_name_filter]
      @customers = Customer.search(current_user.company, filter)
      @users = User.search(current_user.company, filter)
      # add any missing customers to the list
      @users.each { |u| @customers << u.customer }

      @customers = @customers.flatten.uniq.compact
      @customers = @customers.sort_by { |c| c.name.downcase }
     
    end

    render :index
  end

  def show
    @customer = Customer.where("company_id = ?", current_user.company_id).find(params[:id])
  end

  def new
    @customer = current_user.company.customers.new
  end

  def create
    @customer = Customer.new(params[:customer])
    @customer.company = current_user.company
    if @customer.save
      flash['notice'] = _('Client was successfully created.')
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @customer = Customer.where("company_id = ?", current_user.company_id).find(params[:id])
  end

  def update
    @customer = Customer.where("company_id = ?", current_user.company_id).find(params[:id])
    if @customer.update_attributes(params[:customer])
      flash['notice'] = _('Client was successfully updated.')
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    @customer = Customer.where("company_id = ?", current_user.company_id).find(params[:id])
    if @customer.projects.count > 0
      flash['notice'] = _('Please delete all projects for %s before deleting it.', @customer.name)
    else
      if @customer.name == current_user.company.name
        flash['notice'] = _("You can't delete your own company.")
      else
        @customer.destroy
      end
    end
    redirect_to :action => 'index'
  end

  def upload_logo
    if params['customer'].nil? || params['customer']['tmp_file'].nil? || !params['customer']['tmp_file'].respond_to?('original_filename')
      flash['notice'] = _('No file selected.')
      redirect_from_last
      return
    end
    unless params['customer']['tmp_file'].size > 0
      flash['notice'] = _('Empty file uploaded.')
      redirect_from_last
      return
    end

    @customer = Customer.where("company_id = ?", current_user.company_id).find(params['customer']['id'])

    if @customer.logo?
      @customer.logo.destroy rescue begin
                                                flash['notice'] = _("Permission denied while deleting old logo.")
                                                redirect_to :action => 'list'
                                                return
                                              end

    end
    @customer.logo= params['customer']['tmp_file']
    @customer.save!#  rescue begin
                  #    flash['notice'] = _("Permission denied while saving resized file.")
                  #    redirect_to :action => 'list'
                  #    return
                  #  end

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

  # List all logos uploaded
  # Since all this refer to the logos of 'customers' this should be on the customer controller
  def logos
    @customers = Customer.all
  end

  # Show a single logo
  def show_logo
    @customer = Customer.find(params[:id])
    image = Magick::Image.read( @customer.logo_path ).first
    if image
      send_file @customer.logo_path, :filename => "logo", :type => image.mime_type, :disposition => 'inline'
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
