# encoding: UTF-8
class ResourceTypesController < ApplicationController
  before_filter :authorize_user_is_admin
  layout 'admin'

  def index
    @resource_types = current_user.company.resource_types

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => @resource_types }
    end
  end

  def new
    @resource_type = ResourceType.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @resource_type }
    end
  end

  def edit
    @resource_type = current_user.company.resource_types.find(params[:id])
  end

  def create
    @resource_type = ResourceType.new(resource_type_attributes)
    @resource_type.company = current_user.company

    respond_to do |format|
      if @resource_type.save
        flash[:success] = t('flash.notice.model_created', model: ResourceType.model_name.human)
        format.html { redirect_to(edit_resource_type_path(@resource_type)) }
        format.xml { render :xml => @resource_type, :status => :created, :location => @resource_type }
      else
        format.html { render :action => 'new' }
        format.xml { render :xml => @resource_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @resource_type = current_user.company.resource_types.find(params[:id])

    # need to set type_attributes param when all have been deleted
    params[:resource_type][:type_attributes] ||= {}

    saved = @resource_type.update_attributes(resource_type_attributes)
    @resource_type.company = current_user.company
    saved &&= @resource_type.save

    respond_to do |format|
      if saved
        flash[:success] = t('flash.notice.model_updated', model: ResourceType.model_name.human)
        format.html { redirect_to(edit_resource_type_path(@resource_type)) }
        format.xml { head :ok }
      else
        format.html { render :action => 'edit' }
        format.xml { render :xml => @resource_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @resource_type = current_user.company.resource_types.find(params[:id])
    @resource_type.destroy

    respond_to do |format|
      format.html { redirect_to(resource_types_url) }
      format.xml { head :ok }
    end
  end

  def attribute
    render(:partial => 'attribute', :locals => {:attribute => ResourceTypeAttribute.new})
  end

  private

  def resource_type_attributes
    params.require(:resource_type).permit(:name).tap do |whitelist|
      whitelist[:type_attributes] = params[:resource_type][:type_attributes] || {}
      whitelist[:new_type_attributes] = params[:resource_type][:new_type_attributes] || {}
    end
  end
end
