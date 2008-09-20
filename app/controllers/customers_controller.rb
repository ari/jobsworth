# Handle CRUD dealing with Clients, as well as upload of logos.
#
# Logo and CSS should be used when printing reports, or generating a PDF of a report.
class CustomersController < ApplicationController
  require_dependency 'RMagick'

  def index
    list
    render :action => 'list'
  end

  def list
    @customers = Customer.find(:all, :conditions => ["company_id = ?", current_user.company_id], :order => "name")
  end

  def show
    @customer = Customer.find(params[:id],  :conditions => ["company_id = ?", current_user.company_id])
  end

  def new
    @customer = Customer.new
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
    @customer = Customer.find(params[:id],  :conditions => ["company_id = ?", current_user.company_id])
  end

  def update
    @customer = Customer.find(params[:id],  :conditions => ["company_id = ?", current_user.company_id])
    if @customer.update_attributes(params[:customer])
      flash['notice'] = _('Client was successfully updated.')
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    @customer = Customer.find(params[:id],  :conditions => ["company_id = ?", current_user.company_id])
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
    filename = params['customer']['tmp_file'].original_filename
    @customer = Customer.find(params['customer']['id'],  :conditions => ["company_id = ?", current_user.company_id])

    if @customer.logo?
      File.delete(@customer.logo_path) rescue begin
                                                flash['notice'] = _("Permission denied while deleting old logo.")
                                                redirect_to :action => 'list'
                                                return
                                              end

    end

    if !File.directory?(@customer.path)
      Dir.mkdir(@customer.path, 0755) rescue begin
                                                flash['notice'] = _('Unable to create storage directory.')
                                                redirect_to :action => 'list'
                                                return
                                              end
    end

    unless params['customer']['tmp_file'].size > 0
      flash['notice'] = _('Empty file uploaded.')
      redirect_from_last
      return
    end

    File.open(@customer.logo_path, "wb", 0755) { |f| f.write( params['customer']['tmp_file'].read ) } rescue begin
                                                                                                               flash['notice'] = _("Permission denied while saving file.")
                                                                                                               redirect_to :action => 'list'
                                                                                                               return
                                                                                                             end


    if( File.size?(@customer.logo_path).to_i > 0 )
      image = Magick::Image.read( @customer.logo_path ).first

      if image.columns > 250 or image.rows > 50

        if image.columns > image.rows
          scale = 250.0 / image.columns
        else
          scale = 50.0 / image.rows
        end

        if image.rows * scale > 50.0
          scale = 50.0 / image.rows
        end

        image.scale!(scale)

        File.open(@customer.logo_path, "wb", 0777) { |f| f.write( image.to_blob ) } rescue begin
                                                                                             flash['notice'] = _("Permission denied while saving resized file.")
                                                                                             redirect_to :action => 'list'
                                                                                             return
                                                                                           end

      end
    else
      flash['notice'] = _('Empty file.')
      File.delete(@customer.logo_path) rescue begin end
      if params[:company_settings]
         redirect_to :controller => 'companies', :action => 'edit', :id => current_user.company
      else
         redirect_from_last
      end
      return
    end
    GC.start

    flash['notice'] = _('Logo successfully uploaded.')
    if params[:company_settings]
       redirect_to :controller => 'companies', :action => 'edit', :id => current_user.company
    else
       redirect_from_last
    end 
  end

  def delete_logo
    @customer = Customer.find(params[:id], :conditions => ["company_id = ?", current_user.company_id] )
    if !@customer.nil?
      File.delete(@customer.logo_path) rescue begin end
    end
    redirect_from_last
  end

  # Show a clients logo
  def show_logo

    if request.subdomains && request.subdomains.first != 'www'
      company = Company.find(:first, :conditions => ["subdomain = ?", request.subdomains.first])
      @customer = Customer.find(params[:id],  :conditions => ["company_id = ?", company.id])
    else
      @customer = Customer.find(params[:id],  :conditions => ["company_id = ?", current_user.company_id])
    end

    unless @customer.logo?
      render :nothing => true
      return
    end

    image = Magick::Image.read( @customer.logo_path ).first
    if image
      send_file @customer.logo_path, :filename => "logo", :type => image.mime_type, :disposition => 'inline'
    else
      render :nothing => true
    end
    image = nil
    GC.start
  end

end
