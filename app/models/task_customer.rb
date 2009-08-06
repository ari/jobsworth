class TaskCustomer < ActiveRecord::Base
  belongs_to :task, :touch => true
  belongs_to :customer
end
