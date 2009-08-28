module CustomAttributesHelper

  ###
  # Returns a link that will add a new attribute and fields to edit it
  # to the current page.
  ###
  def link_to_add_attribute
    js = "appendPartial('/custom_attributes/fields', '#attributes')"
    link_to_function(_("Add another attribute"), js, :class => "add_attribute")
  end

  ###
  # Returns the form field prefix to use for the given attribute
  ###
  def prefix(attribute)
     prefix = "custom_attributes"
     prefix = "new_#{ prefix }" if attribute.nil? or attribute.new_record? 
    
    return prefix
  end

  ###
  # Returns the form field prefix to use for the given choice
  ###
  def choice_prefix(choice, attribute)
    res = prefix(attribute)
    choice_id = (choice.id || Time.now).to_i
    res += "[#{ attribute.id }][choice_attributes][#{ choice_id }]"

    return res
  end

  ###
  # Returns a link that will add a new choice to attribute and display 
  # it in the current page.
  ###
  def add_choice_link(attribute)
    display = attribute.preset? ? "" : "none"
    link_to_function(_("Add a choice"), "addAttributeChoices(this)", :class => "add_choice_link right_link", :style => "display: #{ display }")
  end

  ###
  # Returns a script tag to make the choices for the given attribute
  # sortable.
  ###
  def sortable_for_choices(attribute)
    div = "##{ dom_id(attribute) } .choices"
    sortable_element(div, 
                     :handle => ".handle.custom_attribute_choice", 
                     :onUpdate => "function() { updatePositionFields('#{ div }') }")
    
  end
end
