class ServicesController < ApplicationController
  before_filter :authorize_user_is_admin

  # GET /services
  # GET /services.json
  def index
    @services = Service.order("name ASC")

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @services }
    end
  end

  # GET /services/1
  # GET /services/1.json
  def show
    @service = Service.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @service }
    end
  end

  # GET /services/new
  # GET /services/new.json
  def new
    @service = Service.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @service }
    end
  end

  # GET /services/1/edit
  def edit
    @service = Service.find(params[:id])
  end

  # POST /services
  # POST /services.json
  def create
    @service = Service.new(params[:service])
    @service.company = current_user.company

    respond_to do |format|
      if @service.save
        format.html { redirect_to services_path, :flash => {success: 'Service was successfully created.' } }
        format.json { render json: @service, status: :created, location: @service }
      else
        format.html { render action: "new" }
        format.json { render json: @service.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /services/1
  # PUT /services/1.json
  def update
    @service = Service.find(params[:id])

    respond_to do |format|
      if @service.update_attributes(params[:service])
        format.html { redirect_to services_path, :flash => {success: 'Service was successfully updated.' } }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @service.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /services/1
  # DELETE /services/1.json
  def destroy
    @service = Service.find(params[:id])
    @service.destroy

    respond_to do |format|
      format.html { redirect_to services_url }
      format.json { head :ok }
    end
  end

  # GET /services?term=xxx
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
