class CustomAttributesController < ApplicationController
  before_filter :check_permission

  def index
    @attributables = []
    @attributables << [ "User", _("User") ]
    @attributables << [ "Customer", _("Client") ]

  end

  def edit
    find_params = { 
      :order => "position", 
      :conditions => { :attributable_type => params[:type] } 
    }

    @attributes = current_user.company.custom_attributes.find(:all, find_params)
  end

  def update
    
  end

  private

  def check_permission
    if !current_user.admin?
      can_view = false
      redirect_to(:controller => "activities", :action => "list")
    end

    return can_view
  end
end
