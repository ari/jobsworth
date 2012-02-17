# encoding: UTF-8
module PropertiesHelper
  def add_value_link
    link_to(_("Add Property Value"), "#", {
      "data-property" => render_to_string(
        partial: 'property_value',
        locals: {
          pv: @property.property_values.build
        }),
      id: 'add_value_link',
      class: 'btn'
    })
  end

end
