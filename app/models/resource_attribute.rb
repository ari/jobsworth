class ResourceAttribute < ActiveRecord::Base
  belongs_to :resource
  belongs_to :resource_type_attribute
end
