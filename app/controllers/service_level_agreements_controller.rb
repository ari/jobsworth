class ServiceLevelAgreementsController < ApplicationController
  before_filter :authorize_user_is_admin

  def index
    @service_level_agreements = ServiceLevelAgreement.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @service_level_agreements }
    end
  end

  def show
    @service_level_agreement = current_user.company.service_level_agreements.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @service_level_agreement }
    end
  end

  def new
    @service_level_agreement = ServiceLevelAgreement.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @service_level_agreement }
    end
  end

  def edit
    @service_level_agreement = current_user.company.service_level_agreements.find(params[:id])
  end

  def create
    @service_level_agreement = ServiceLevelAgreement.new(params[:service_level_agreement])
    @service_level_agreement.company_id = current_user.company_id

    if ServiceLevelAgreement.where(:service_id => @service_level_agreement.service_id).where(:customer_id => @service_level_agreement.customer_id).count > 0
      return render :json => {
        success: false,
        message: t('flash.error.pair_already_added',
                   first: @service_level_agreement.service.name,
                   second: @service_level_agreement.customer.name)
      }
    end

    if @service_level_agreement.save
      html = render_to_string :partial => "service_level_agreements/service_level_agreement", :locals => {:service_level_agreement => @service_level_agreement}
      render :json => {:success => true, :html => html}
    else
      render :json => {:success => false, :message => @service_level_agreement.errors.full_messages.join(". ") }
    end
  end

  # PUT /service_level_agreements/1
  # PUT /service_level_agreements/1.json
  def update
    @service_level_agreement = current_user.company.service_level_agreements.find(params[:id])

    if @service_level_agreement.update_attributes(params[:service_level_agreement])
      render :json => {:success => true}
    else
      render :json => {:success => false, :message => @service_level_agreement.errors.full_messages.join(". ") }
    end
  end

  # DELETE /service_level_agreements/1
  # DELETE /service_level_agreements/1.json
  def destroy
    @service_level_agreement = current_user.company.service_level_agreements.find(params[:id])
    @service_level_agreement.destroy

    render :json => {:success => true}
  end
end
