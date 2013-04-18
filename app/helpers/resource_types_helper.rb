# encoding: UTF-8
module ResourceTypesHelper
  ###
  # Returns the html to add an attribute to the currently shown
  # resource type.
  ###
  def add_attribute_link
    js = "jQuery.get('/resource_types/attribute', function(data) { jQuery('#resource_type_attributes').append(data); }, 'html')"
    link_to_function(t('forms.action.add', model: t('shared.another_attribute')), js, :class => "add_attribute btn")
  end

end
