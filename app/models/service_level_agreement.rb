class ServiceLevelAgreement < ActiveRecord::Base
  belongs_to :customer
  belongs_to :service

  validates :customer_id, :uniqueness => {:scope => "service_id"}
end

# == Schema Information
#
# Table name: service_level_agreements
#
#  id          :integer(4)      not null, primary key
#  service_id  :integer(4)
#  customer_id :integer(4)
#  billable    :boolean(1)
#  company_id  :integer(4)
#  created_at  :datetime
#  updated_at  :datetime
#

