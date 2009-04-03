module ResourceTypesHelper
  ###
  # Returns the html to add an attribute to the currently shown
  # resource type.
  ###
  def add_attribute_link
    link_to_function(_("Add another attribute")) do |page|
      attr = @resource_type.resource_type_attributes.build
      page.insert_html(:bottom, "resource_type_attributes", 
                       :partial => "attribute", 
                       :locals => { :attribute => attr })
    end
  end

end
