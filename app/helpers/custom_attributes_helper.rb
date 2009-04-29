module CustomAttributesHelper
  def link_to_add_attribute
    link_to_function(_("Add another attribute"), "addAttributeFields()")
  end
end
