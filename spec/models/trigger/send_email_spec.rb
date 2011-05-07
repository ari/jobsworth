require 'spec_helper'
describe Trigger::SendEmail do
  before(:all) do
    @action = Trigger::SendEmail.new
  end
end

# == Schema Information
#
# Table name: trigger_actions
#
#  id         :integer(4)      not null, primary key
#  trigger_id :integer(4)
#  name       :string(255)
#  type       :string(255)
#  argument   :integer(4)
#  created_at :datetime
#  updated_at :datetime
#

