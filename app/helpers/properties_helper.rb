module PropertiesHelper
  def add_value_link
    link_to_function(_"Add") do |page|
      pv = @property.property_values.build
      page.insert_html(:bottom, "property_values", :partial => "property_value", 
                       :locals => { :pv => pv })
    end
  end

  def cit_submit_tag(object)
    text = object.new_record? ? _("Create") : _("Update")
    
    submit_tag(text, :class => 'nolabel')
  end

  def link_to_remove_value
    image = image_tag("cross_small.png", :border => 0, 
                      :alt => "#{ _("Remove") }")
    link_to_function(image, '$(this).up(".property_value").remove();')
  end
end
