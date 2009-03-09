module ResourcesHelper
  ###
  # Returns an array that can be used to select what the
  # type of a resource is.
  ###
  def resource_types_options_array
    current_user.company.resource_types.map { |rt| [rt.name, rt.id] }
  end
end
