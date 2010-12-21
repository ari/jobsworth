class EmailDelivery < ActiveRecord::Base
  belongs_to :work_log
  belongs_to :email_address
end
