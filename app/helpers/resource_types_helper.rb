module ResourceTypesHelper
  ###
  # Returns the html to add an attribute to the currently shown
  # resource type.
  ###
  def add_attribute_link
    link_to_function(_"Add") do |page|
      attr = @resource_type.resource_type_attributes.build
      page.insert_html(:bottom, "resource_type_attributes", 
                       :partial => "attribute", 
                       :locals => { :attribute => attr })
    end
  end

  ###
  # Returns the html to show a choice field for field called name.
  # Ideally, this would use a checkbox, but checkboxes seem to be 
  # confusing the arrays in the params that rails gets, so using
  # a select for now.
  ###
  def boolean_choice_field(form, name, attribute)
    options = []
    options << [ "Yes", 1 ]
    options << [ "No", 0 ]

    selected = attribute.send(name) ? 1 : 0
    index = attribute.id

    return form.select(name, options, { :selected => selected }, 
                       :index => index)
  end
end
