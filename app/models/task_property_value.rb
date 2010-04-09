###
# A TaskPropertyValue links a task with a particular property
# and a value for that property.
###
class TaskPropertyValue < ActiveRecord::Base
  belongs_to :task
  belongs_to :property
  belongs_to :property_value

end


# == Schema Information
#
# Table name: task_property_values
#
#  id                :integer(4)      not null, primary key
#  task_id           :integer(4)
#  property_id       :integer(4)
#  property_value_id :integer(4)
#
# Indexes
#
#  index_task_property_values_on_task_id      (task_id)
#  index_task_property_values_on_property_id  (property_id)
#

