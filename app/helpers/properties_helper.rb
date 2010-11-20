# encoding: UTF-8
module PropertiesHelper
  def add_value_link
    link_to_function(_("Add")) do |page|
      pv = @property.property_values.build
      html = render_to_string(:partial => 'property_value', :locals => { :pv => pv })
      page << "jQuery('#property_values').append('#{escape_javascript html}')"
    end
  end

end
