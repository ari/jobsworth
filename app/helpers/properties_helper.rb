module PropertiesHelper
  def add_value_link
    link_to_function(_"Add") do |page|
      pv = @property.property_values.build
      page.insert_html(:bottom, "property_values", :partial => "property_value", 
                       :locals => { :pv => pv })
    end
  end

end
