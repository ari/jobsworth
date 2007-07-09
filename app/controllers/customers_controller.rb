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
      flash['notice'] = _('Client was successfully created.')
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
      flash['notice'] = _('Client was successfully updated.')
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    @customer = Customer.find(@params[:id],  :conditions => ["company_id = ?", session[:user].company_id])
    if @customer.projects.count > 0
      flash['notice'] = _('Please delete all projects for %s before deleting it.', @customer.name)
    else
      if @customer.name == session[:user].company.name
        flash['notice'] = _("You can't delete your own company.")
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
      flash['notice'] = _('CSS successfully uploaded.')
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

    if !@customer.logo? || !File.directory?(@customer.path)
      Dir.mkdir(@customer.path, 0755) rescue begin
                                                flash['notice'] = _('Unable to create storage directory.')
                                                redirect_to :action => 'list'
                                                return
                                              end
    end
    File.open(@customer.logo_path, "wb", 0755) { |f| f.write( params['customer']['tmp_file'].read ) } rescue begin
                                                                                                               flash['notice'] = _("Permission denied while saving file.")
                                                                                                               redirect_to :action => 'list'
                                                                                                               return
                                                                                                             end


    if( File.size?(@customer.logo_path).to_i > 0 )
      image = Magick::Image.read( @customer.logo_path ).first

      if image.columns > 250 or image.rows > 100

        if image.columns > image.rows
          scale = 250.0 / image.columns
        else
          scale = 100.0 / image.rows
        end
        image.scale!(scale)

        File.open(@customer.logo_path, "wb", 0777) { |f| f.write( image.to_blob ) } rescue begin
                                                                                             flash['notice'] = _("Permission denied while saving resized file.")
                                                                                             redirect_to :action => 'list'
                                                                                             return
                                                                                           end

      end
      GC.start
    else
      flash['notice'] = _('Empty file.')
      redirect_from_last
      return
    end

    flash['notice'] = _('Logo successfully uploaded.')
    redirect_from_last
  end

  def delete_logo
    @customer = Customer.find(@params[:id], :conditions => ["company_id = ?", session[:user].company_id] )
    if !@customer.nil?
      File.delete(@customer.logo_path) rescue begin end
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

    unless @customer.logo?
      render :nothing => true
      return
    end

    image = Magick::Image.read( @customer.logo_path ).first
    send_data image.to_blob, :filename => "logo", :type => image.mime_type, :disposition => 'inline'
  end

end
