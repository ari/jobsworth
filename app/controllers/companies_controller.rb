# encoding: UTF-8
class CompaniesController < ApplicationController
  before_filter :authorize_user_is_admin, :except => [:show_logo, :properties]

  layout 'admin'

  def edit
    @company = current_user.company
  end

  def score_rules
    @company = current_user.company
  end

  def custom_scripts
    @company = current_user.company
  end

  def update
    @company = current_user.company

    #TODO: When refactoring the model, remove this whole 'internal_customer' thingy,
    # as far as I can tell, the internal customer is only used for storing the
    # company logo.
    @internal = @company.internal_customer
    if @internal.nil?
      flash[:error] = t('error.company.no_internal_customer')
      render :action => 'edit'
      return
    end

    if @company.update_attributes(params[:company])
      @internal.name = @company.name
      @internal.save

      flash[:success] = t('flash.notice.settings_updated', model: Company.model_name.human)
      redirect_from_last
    else
      flash[:error] = @company.errors.full_messages.join(". ")
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

  # get company properties in JSON format
  def properties
    @properties = current_user.company.properties
    render :json => @properties
  end
end
