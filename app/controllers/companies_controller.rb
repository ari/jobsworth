# encoding: UTF-8
class CompaniesController < ApplicationController
  before_filter :authorize_user_is_admin

  def edit
    @company = current_user.company
  end

  def update
    @company = current_user.company

    #TODO: When refactoring the model, remove this whole 'internal_customer' thingy,
    # as far as I can tell, the internal customer is only used for storing the 
    # company logo.
    @internal = @company.internal_customer
    if @internal.nil?
      flash['notice'] = 'Unable to find internal customer.'
      render :action => 'edit'
      return
    end

    if @company.update_attributes(params[:company])
      @internal.name = @company.name
      @internal.save

      flash['notice'] = _('Company settings updated')
      redirect_from_last
    else
      render :action => 'edit'
    end
  end

  # Show a company logo
  def show_logo
    company = Company.find(params[:id])

    if company.logo?
      send_file(company.logo_path, :filename => "logo", :disposition => "inline", :type => company.logo_content_type)
    else
      render :nothing => true
    end
  end

  def upload_logo
    if params['company'].nil? ||
       params['company']['tmp_file'].nil? ||
       !params['company']['tmp_file'].respond_to?('original_filename')
      flash['notice'] = _('No file selected.')
      redirect_from_last
      return
    end

    unless params['company']['tmp_file'].size > 0
      flash['notice'] = _('Empty file uploaded.')
      redirect_from_last
      return
    end

    @company = current_user.company
    if @company.logo?
      @company.logo.destroy rescue begin
        flash['notice'] = _("Permission denied while deleting old logo.")
        redirect_from_last
        return
      end
    end

    @company.logo= params['company']['tmp_file']
    @company.save!

    flash['notice'] = _('Logo successfully uploaded.')

    redirect_to :controller => 'companies', :action => 'edit', :id => @company
  end

  def delete_logo
    @company = current_user.company

    if @company.logo?
      @company.logo.destroy rescue begin end
    end
    redirect_from_last
  end

end
