class Service < ActiveRecord::Base
  belongs_to :company
  has_many :service_level_agreements, :dependent => :destroy

  validates_presence_of :name
  validates_uniqueness_of  :name, :scope => 'company_id', :case_sensitive => false
end

# == Schema Information
#
# Table name: services
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)
#  description :text
#  company_id  :integer(4)
#  created_at  :datetime
#  updated_at  :datetime
#

