# encoding: UTF-8
class ResourcesController < ApplicationController
  before_filter :check_permission

  layout :decide_layout

  def new
    @resource = Resource.new
    @resource.customer_id = params[:customer_id]

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @resource }
    end
  end

  def show
    redirect_to(params.merge(:action => "edit"))
  end

  def edit
    @resource = current_user.company.resources.find(params[:id])
  end

  def create
    @resource = Resource.new
    @resource.company = current_user.company

    respond_to do |format|
      if @resource.update_attributes(params[:resource])
        flash[:success] = 'Resource was successfully created.'
        format.html { redirect_to(edit_resource_path(@resource)) }
        format.xml  { render :xml => @resource, :status => :created, :location => @resource }
      else
        flash[:error] = @resource.errors.full_messages.join(". ")
        format.html { render :action => "new" }
        format.xml  { render :xml => @resource.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @resource = current_user.company.resources.find(params[:id])
    @resource.attributes = params[:resource]
    @resource.company = current_user.company
    log = log_resource_changes(@resource)
    
    respond_to do |format|
      if @resource.save
        # BW: not sure why these aren't getting updated automatically
        @resource.resource_attributes.each { |ra| ra.save }
        log.save! if log

        flash[:success] = 'Resource was successfully updated.'
        format.html { redirect_to(edit_resource_path(@resource)) }
        format.xml  { head :ok }
      else
        flash[:error] = @resource.errors.full_messages.join(". ")
        format.html { render :action => "edit" }
        format.xml  { render :xml => @resource.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @resource = current_user.company.resources.find(params[:id])
    @resource.destroy

    respond_to do |format|
      format.html { redirect_to root_path }
      format.xml  { head :ok }
    end
  end

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

  def show_password
    resource = current_user.company.resources.find(params[:id])
    @attribute = resource.resource_attributes.find(params[:attr_id])
    
    body = "Requested password for resource "
    body += "#{ resource_path(resource) } - #{ resource.name }"

    el = EventLog.new(:user => current_user,
                     :company => current_user.company,
                     :event_type => EventLog::RESOURCE_PASSWORD_REQUESTED,
                     :body => CGI::escapeHTML(body),
                      :target => resource
                     )
    el.save!
    render :partial => "show_password", :layout => false
  end

  def auto_complete_for_resource_parent_id
    search = params[:term]
    search = search[:parent_id] if search
    @resources = []
    if !search.blank?
      cond = [ "lower(name) like ?", "%#{ search.downcase }%" ]
      @resources = current_user.company.resources.where(cond)
      render :json=> @resources.collect{|resource| {:value => resource.name, :id=> resource.id} }.to_json
    end
  end

  private

  def check_permission
    redirect_to root_path unless current_user.use_resources?
  end

  ###
  # Returns an unsaved event log of any changed attributes in resource.
  # Save the response to add it to the system event log.
  ###
  def log_resource_changes(resource)
    all_changes = resource.changes_as_html
    resource.resource_attributes.each { |ra| all_changes += ra.changes_as_html }

    return if all_changes.empty?

    body = all_changes.join(", ")
    el = EventLog.new(:user => current_user,
                 :company => current_user.company,
                 :event_type => EventLog::RESOURCE_CHANGE,
                 :body => body,
                 :target => @resource
                 )
    return el
  end
end
