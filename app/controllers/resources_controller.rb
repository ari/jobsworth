class ResourcesController < ApplicationController
  # GET /resources
  # GET /resources.xml
  def index
    @resources = current_user.company.resources

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @resources }
    end
  end

  # GET /resources/new
  # GET /resources/new.xml
  def new
    @resource = Resource.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @resource }
    end
  end

  # GET /resources/1/edit
  def edit
    @resource = current_user.company.resources.find(params[:id])
  end

  # POST /resources
  # POST /resources.xml
  def create
    @resource = Resource.new
    @resource.company = current_user.company

    respond_to do |format|
      if @resource.update_attributes(params[:resource])
        flash[:notice] = 'Resource was successfully created.'
        format.html { redirect_to(edit_resource_path(@resource)) }
        format.xml  { render :xml => @resource, :status => :created, :location => @resource }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @resource.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /resources/1
  # PUT /resources/1.xml
  def update
    @resource = current_user.company.resources.find(params[:id])
    @resource.attributes = params[:resource]
    @resource.company = current_user.company

    respond_to do |format|
      if @resource.save
        # BW: not sure why these aren't getting updated automatically
        @resource.resource_attributes.each { |ra| ra.save }

        flash[:notice] = 'Resource was successfully updated.'
        format.html { redirect_to(edit_resource_path(@resource)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @resource.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /resources/1
  # DELETE /resources/1.xml
  def destroy
    @resource = current_user.company.resources.find(params[:id])
    @resource.destroy

    respond_to do |format|
      format.html { redirect_to(resources_url) }
      format.xml  { head :ok }
    end
  end

  # GET /resources/attributes/?type_id=1
  def attributes
    type = current_user.company.resource_types.find(params[:type_id])
    rtas = type.resource_type_attributes

    attributes = rtas.map do |rta| 
      attr = ResourceAttribute.new
      attr.resource_type_attribute = rta
      attr
    end

    render :partial => "attribute", :collection => attributes
  end

  # GET /resources/1/show_password?attr_id=2
  def show_password
    resource = current_user.company.resources.find(params[:id])
    attribute = resource.resource_attributes.find(params[:attr_id])
    
    body = "Requested password for resource "
    body += "<a href=\"#{ edit_resource_path(resource) }\">#{ resource.name }</a>"

    wl = WorkLog.new(:user => current_user,
                     :started_at => Time.now.utc,
                     :duration => 0,
                     :company => current_user.company,
                     :log_type => EventLog::RESOURCE_PASSWORD_REQUESTED,
                     :body => CGI::escapeHTML(body),
                     :comment => true)
    wl.save!
    
    render :text => attribute.value
  end

end

