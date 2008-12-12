class TaskPropertyValue < ActiveRecord::Base
  belongs_to :task
  belongs_to :property
  belongs_to :property_value
end
