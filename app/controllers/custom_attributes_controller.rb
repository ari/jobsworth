class CustomAttributesController < ApplicationController
  before_filter :check_permission

  def index
    @attributables = []
    @attributables << [ "User", _("User") ]
    @attributables << [ "Customer", _("Client") ]
    @attributables << [ "OrganizationalUnit", _("Organizational Unit") ]
    @attributables << [ "WorkLog", _("Work Log") ]
  end

  def edit
    @attributes = CustomAttribute.attributes_for(current_user.company, params[:type])
  end

  def update
    update_existing_attributes(params) 
    create_new_attributes(params) if params[:new_custom_attributes]

    flash[:notice] = _("Custom attributes updated")
    redirect_to(:action => "edit", :type => params[:type])
  end

  def fields
    render(:partial => "attribute", :locals => { :attribute => CustomAttribute.new })
  end

  def choice
    attribute = CustomAttribute.new
    if params[:id]
      attribute = current_user.company.custom_attributes.find(params[:id])
    end

    render(:partial => "choice", :locals => { 
             :attribute => attribute, :choice => CustomAttributeChoice.new })
  end

  private

  def update_existing_attributes(params)
    attributes = CustomAttribute.attributes_for(current_user.company, params[:type])

    updated = []
    (params[:custom_attributes] || {}).each do |id, values|
      # need to ensure this is set so can delete all
      values[:choice_attributes] ||= {}

      attr = attributes.detect { |ca| ca.id == id.to_i }
      updated << attr

      attr.update_attributes(values)
    end
    missing = attributes - updated
    missing.each { |ca| ca.destroy }
  end

  def create_new_attributes(params)
    attributes = CustomAttribute.attributes_for(current_user.company, params[:type])
    offset = attributes.length

    params[:new_custom_attributes].each_with_index do |values, i|
      values[:attributable_type] = params[:type]
      values[:position] = offset + i
      current_user.company.custom_attributes.create(values)
    end
  end

  def check_permission
    if !current_user.admin?
      can_view = false
      redirect_to(:controller => "activities", :action => "list")
    end

    return can_view
  end
end
