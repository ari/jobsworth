# encoding: UTF-8
# Handle CRUD dealing with Clients, as well as upload of logos.
#
# Logo and CSS should be used when printing reports, or generating a PDF of a report.
class ClientsController < ApplicationController
  before_filter :check_can_access, :except => [:show_logo]

  def index
    redirect_to(:action => 'list')
  end

  def list
  if request.post?
      session[:client_name_filter] = params[:search_text].strip
    end

    if !session[:client_name_filter].blank?
        filter = []
      filter << session[:client_name_filter]
      @customers = Customer.search(current_user.company, filter)
      @users = User.search(current_user.company, filter)
      # add any missing customers to the list
      @users.each { |u| @customers << u.customer }

    @customers = @customers.flatten.uniq.compact
    @customers = @customers.sort_by { |c| c.name.downcase }
    @paginate = false
  else
    @customers = Customer.where("customers.company_id = ?", current_user.company_id).order("customers.name").paginate(:page => params[:page], :per_page => 100)
    @paginate = true
    end
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
    redirect_to :action => 'list'
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

  ###
  # Checks to see if the current user is allowed to view this section
  # of the site.
  ###
  def check_can_access
    res = false
    read_actions = [ "index", "list", "edit" ]
    new_actions = [ "new", "create" ]
    edit_actions = [ "edit", "update", "destroy", "update_logo" ]

    res ||= (action_name == "show_logo")
    res ||= current_user.admin?

    res ||= (current_user.read_clients? and read_actions.include?(action_name))
    res ||= (current_user.edit_clients? and edit_actions.include?(action_name))
    res ||= (current_user.create_clients? and new_actions.include?(action_name))

    if !res
      flash["notice"] = _("Access denied")
      redirect_from_last
    end
  end
end
