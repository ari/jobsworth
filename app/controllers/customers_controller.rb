# Handle CRUD dealing with Clients, as well as upload of logos.
#
# Logo and CSS should be used when printing reports, or generating a PDF of a report.
class CustomersController < ApplicationController
  require 'RMagick'

  def index
    list
    render_action 'list'
  end

  def list
    @customer_pages, @customers = paginate :customer, :per_page => 15, :conditions => ["company_id = ?", session[:user].company_id]
  end

  def show
    @customer = Customer.find(@params[:id],  :conditions => ["company_id = ?", session[:user].company_id])
  end

  def new
    @customer = Customer.new
  end

  def create
    @customer = Customer.new(@params[:customer])
    @customer.company = session[:user].company
    if @customer.save
      flash['notice'] = 'Client was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @customer = Customer.find(@params[:id],  :conditions => ["company_id = ?", session[:user].company_id])
  end

  def update
    @customer = Customer.find(@params[:id],  :conditions => ["company_id = ?", session[:user].company_id])
    if @customer.update_attributes(@params[:customer])
      flash['notice'] = 'Client was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    @customer = Customer.find(@params[:id],  :conditions => ["company_id = ?", session[:user].company_id])
    if @customer.projects.count > 0
      flash['notice'] = "Please delete all projects for #{@customer.name} before destroying."
    else
      if @customer.name == session[:user].company.name
        flash['notice'] = "You can't delete your own company."
      else
        @customer.destroy
      end
    end
    redirect_to :action => 'list'
  end

  def upload_css
    filename = @params['customer']['tmp_file'].original_filename
    @customer = Customer.find(@params['customer']['id'],  :conditions => ["company_id = ?", session[:user].company_id])
    @customer.css = @params['customer']['tmp_file'].read
    @params['customer'].delete('tmp_file')

    if @customer.save
      flash['notice'] = 'CSS successfully uploaded.'
      redirect_to :action => 'list'
    else
      render_action 'edit'
    end
  end


  def upload_logo
    filename = @params['customer']['tmp_file'].original_filename
    @customer = Customer.find(@params['customer']['id'],  :conditions => ["company_id = ?", session[:user].company_id])

    if !@customer.binary.nil?
      @customer.binary.destroy
    end

    @binary = Binary.new
    @binary.data = @params['customer']['tmp_file'].read
    @binary.save
    @customer.binary = @binary
    @params['customer'].delete('tmp_file')

    if @customer.save
      flash['notice'] = 'Logo successfully uploaded.'
      redirect_from_last
    else
      render_action 'edit'
    end
  end

  def delete_logo
    @customer = Customer.find(@params[:id], :conditions => ["company_id = ?", session[:user].company_id] )
    if !@customer.nil?
      @customer.binary.destroy
      @customer.binary_id = nil
      @customer.save
    end
    redirect_from_last
  end

  # Show a clients logo
  def show_logo
    if request.subdomains && request.subdomains.first != 'www'
      company = Company.find(:first, :conditions => ["subdomain = ?", request.subdomains.first])
      @customer = Customer.find(@params[:id],  :conditions => ["company_id = ?", company.id])
    else
      @customer = Customer.find(@params[:id],  :conditions => ["company_id = ?", session[:user].company_id])
    end
    image = Magick::Image.from_blob( @customer.binary.data ).first
    send_data image.to_blob, :filename => "logo", :type => image.mime_type, :disposition => 'inline'
  end

end
