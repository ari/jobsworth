module ResourceTypesHelper
  def add_attribute_link
    link_to_function(_"Add") do |page|
      attr = @resource_type.resource_type_attributes.build
      page.insert_html(:bottom, "resource_type_attributes", 
                       :partial => "attribute", 
                       :locals => { :attribute => attr })
    end
  end

end
