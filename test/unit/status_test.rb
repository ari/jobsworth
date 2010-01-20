require 'test_helper'

class StatusTest < ActiveSupport::TestCase
  should_belong_to :company
  should_validate_presence_of :company
end

# == Schema Information
#
# Table name: statuses
#
#  id         :integer(4)      not null, primary key
#  company_id :integer(4)
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

