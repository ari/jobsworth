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
# Indexes
#
#  fk_task_customers_customer_id  (customer_id)
#  fk_task_customers_task_id      (task_id)
#

