# encoding: UTF-8
module PropertiesHelper
  def add_value_link
    link_to(t('forms.action.add', model: PropertyValue.model_name.human), '#', {id: 'add_value_link', class: 'btn' })
    render :partial => 'property_value', :locals => { pv: @property.property_values.build }
  end

end
