# encoding: UTF-8
module CustomAttributesHelper

  ###
  # Returns a link that will add a new attribute and fields to edit it
  # to the current page.
  ###
  def link_to_add_attribute
    js = "appendPartial('/custom_attributes/fields', '#attributes')"
    link_to_function(_("Add another attribute"), js, :class => "add_attribute btn")
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


  def edit_custom_attribute_link_for(entity)
    # This will transform some_entity to Some entities
    link_text = entity.humanize.capitalize.pluralize
    # This will transform some_entity to SomeEntity
    attr_type = entity.split('_').map { |w| w.capitalize }.join('')

    link_to(_(link_text), :action => "edit", :type => attr_type)
  end  
end
