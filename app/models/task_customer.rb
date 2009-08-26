class TaskCustomer < ActiveRecord::Base
  belongs_to :task
  belongs_to :customer
end
