require 'spec_helper'
describe Trigger::Action do
  before(:all) do
    @action = Trigger::Action.new
  end

  it "should has id attribute" do
    @action.id = 12
    @action.id.should == 12
  end

  it "should has name attribute" do
    @action.name = "reassing"
    @action.name.should == "reassing"
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

