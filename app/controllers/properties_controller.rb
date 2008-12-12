class PropertiesController < ApplicationController
  # GET /properties
  # GET /properties.xml
  def index
    if current_user.admin > 0
      @properties = Property.all_for_company(current_user.company)
      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @properties }
      end
    else
      redirect_to :action => 'edit_preferences'
    end
  end

  # GET /properties/1
  # GET /properties/1.xml
  def show
    @property = Property.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @property }
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
    @property = Property.find(params[:id])
  end

  # POST /properties
  # POST /properties.xml
  def create
    @property = Property.new(params[:property])
    @property.property_values.build(params[:new_property_values]) if params[:new_property_values]
    @property.company = current_user.company

    respond_to do |format|
      if @property.save
        flash[:notice] = 'Property was successfully created.'
        format.html { redirect_to(edit_properties_path(@property)) }
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
    @property = Property.find(params[:id])
    update_existing_property_values(@property, params)
    @property.property_values.build(params[:new_property_values]) if params[:new_property_values]

    respond_to do |format|
      if @property.update_attributes(params[:property]) and @property.save
        flash[:notice] = 'Property was successfully updated.'
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
    @property = Property.find(params[:id])
    @property.destroy

    respond_to do |format|
      format.html { redirect_to(properties_url) }
      format.xml  { head :ok }
    end
  end

  private

  def update_existing_property_values(property, params)
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
