# encoding: UTF-8
class PropertiesController < ApplicationController
  before_filter :authorize_user_is_admin
  layout  "admin"

  # GET /properties
  # GET /properties.xml
  def index
    @properties = current_user.company.properties
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @properties }
    end
  end

  # GET /properties/new
  # GET /properties/new.xml
  def new
    @property = Property.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @property }
    end
  end

  # GET /properties/1/edit
  def edit
    @property = current_user.company.properties.find(params[:id])
  end

  # POST /properties
  # POST /properties.xml
  def create
    @property = Property.new(params[:property])
    @property.property_values.build(params[:new_property_values]) if params[:new_property_values]
    @property.company = current_user.company

    respond_to do |format|
      if @property.save
        flash[:success] = t('flash.notice.model_created', model: Property.model_name.human)
        format.html { redirect_to(edit_property_path(@property)) }
        format.xml  { render :xml => @property, :status => :created, :location => @property }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @property.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /properties/1
  # PUT /properties/1.xml
  def update
    @property = current_user.company.properties.find(params[:id])
    update_existing_property_values(@property, params)
    @property.property_values.build(params[:new_property_values]) if params[:new_property_values]

    saved = @property.update_attributes(params[:property])
    # force company in case somebody passes in company_id param
    @property.company = current_user.company
    saved &&= @property.save

    respond_to do |format|
      if saved
        flash[:success] = t('flash.notice.model_updated', model: Property.model_name.human)
        format.html { redirect_to(edit_property_path(@property)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @property.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /properties/1
  # DELETE /properties/1.xml
  def destroy
    @property = current_user.company.properties.find(params[:id])
    @property.destroy

    respond_to do |format|
      format.html { redirect_to(properties_url) }
      format.xml  { head :ok }
    end
  end

  def order
    if params[:property_values]
      values = params[:property_values].map { |id| PropertyValue.find(id) }
      # if it's a new record, we can just ignore this (because update will use the correct order)
      if values.first.property
        values.each_with_index do |v, i|
          v.position = i
          v.save
        end
      end
    end

    render :text => ''
  end

  # GET /properties/remove_property_value_dialog
  # params:
  #   property_value_id
  def remove_property_value_dialog
    @pv = PropertyValue.find(params[:property_value_id])
    render :layout => false
  end

  # POST /properties/remove_property_value
  # params:
  #   property_value_id
  #   replace_with
  def remove_property_value
    @pv = PropertyValue.find(params[:property_value_id])

    # check if user can access this property value
    if current_user.company != @pv.property.company
      return render json: {success: false, message: t('flash.alert.access_denied_to_model', model: Property.model_name.human)}
    end

    # if delete directly
    if !params[:replace_with].blank?
      # if replace with another value
      @replace_with = PropertyValue.find(params[:replace_with])
      # check if user can access this property value
      if current_user.company != @replace_with.property.company
        return render json: {success: false, message: t('flash.alert.access_denied_to_model', model: Property.model_name.human)}
      end

      @pv.task_property_values.each {|tpv| @replace_with.task_property_values << tpv}
      @pv.task_filter_qualifiers.each {|tfq| @replace_with.task_filter_qualifiers << tfq}
    end

    # reload is important
    @pv.reload.destroy
    return render :json => { :success => true }
  end

  private

  def update_existing_property_values(property, params)
    return if !property or !params[:property_values]

    property.property_values.each do |pv|
      posted_vals = params[:property_values][pv.id.to_s]
      if posted_vals
        pv.update_attributes(posted_vals)
      else
        property.property_values.delete(pv)
      end
    end
  end

end
