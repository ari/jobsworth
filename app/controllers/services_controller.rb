class ServicesController < ApplicationController
  before_filter :authorize_user_is_admin

  layout  "admin"

  def index
    @services = current_user.company.services.order("name ASC")

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @services }
    end
  end

  def show
    @service = current_user.company.services.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @service }
    end
  end

  def new
    @service = Service.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @service }
    end
  end

  def edit
    @service = current_user.company.services.find(params[:id])
  end

  def create
    @service = Service.new(params[:service])
    @service.company = current_user.company

    respond_to do |format|
      if @service.save
        format.html { redirect_to services_path, notice: t('flash.notice.model_created', model: Service.model_name.human) }
        format.json { render json: @service, status: :created, location: @service }
      else
        format.html { render action: "new" }
        format.json { render json: @service.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @service = current_user.company.services.find(params[:id])

    respond_to do |format|
      if @service.update_attributes(params[:service])
        format.html { redirect_to services_path, notice: t('flash.notice.model_updated', model: Service.model_name.human) }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @service.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @service = current_user.company.services.find(params[:id])
    @service.destroy

    respond_to do |format|
      format.html { redirect_to services_url }
      format.json { head :ok }
    end
  end

  def auto_complete_for_service_name
    text = params[:term]
    if !text.blank?
      @services = current_user.company.services.order('name').where('name LIKE ? OR name LIKE ?', text + '%', '% ' + text + '%').limit(50)
      render :json=> @services.collect{|service| {:value => service.name, :id=> service.id} }.to_json
    else
      render :nothing=> true
    end
  end

end
