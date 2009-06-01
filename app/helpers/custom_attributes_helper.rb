module CustomAttributesHelper
  def link_to_add_attribute
    js = "appendPartial('/custom_attributes/fields', '#attributes')"
    link_to_function(_("Add another attribute"), js, :class => "add_attribute")
  end
end
