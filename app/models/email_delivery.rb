class EmailDelivery < ActiveRecord::Base
  belongs_to :work_log
  belongs_to :email_address
end

# == Schema Information
#
# Table name: email_deliveries
#
#  id               :integer(4)      not null, primary key
#  work_log_id      :integer(4)
#  email_address_id :integer(4)
#  status           :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#

