# encoding: UTF-8
###
# A TaskPropertyValue links a task with a particular property
# and a value for that property.
###
class TaskPropertyValue < ActiveRecord::Base
  belongs_to :task, :class_name=>"AbstactTask"
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
#  task_property  (task_id,property_id) UNIQUE
#

