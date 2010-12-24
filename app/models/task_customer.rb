# encoding: UTF-8
class TaskCustomer < ActiveRecord::Base
  belongs_to :task, :class_name=>"AbstractTask"
  belongs_to :customer
end



# == Schema Information
#
# Table name: task_customers
#
#  id          :integer(4)      not null, primary key
#  customer_id :integer(4)
#  task_id     :integer(4)
#  created_at  :datetime
#  updated_at  :datetime
#

