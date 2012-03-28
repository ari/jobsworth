# encoding: UTF-8
class PropertiesController < ApplicationController
  # GET /properties
  # GET /properties.xml
  def index
    if current_user.admin > 0
      @properties = current_user.company.properties
      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @properties }
      end
    else
      redirect_to :action => 'edit_preferences'
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
        flash[:success] = 'Property was successfully created.'
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
        flash[:success] = 'Property was successfully updated.'
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
