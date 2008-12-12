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
end
