class ResourceTypeAttribute < ActiveRecord::Base
  belongs_to :resource_type
  acts_as_list :scope => :resource_type

  validates_presence_of :name
end
