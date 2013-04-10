def ToID(resource)
  resource.is_a?(ActiveRecord::Base) ? resource.id : resource
end

def ToIDs(*resources)
  ids = resources.flatten(1).map {|r| ToID(r) }
  ids.size < 2 ? ids.first : ids
end
