require 'spec_helper'

describe AccessLevel do
  before(:each) do
    @valid_attributes = {
        :name => 'customer'
    }
  end

  it 'should create a new instance given valid attributes' do
    AccessLevel.create!(@valid_attributes)
  end
  it 'should has many worklogs' do
    expect(AccessLevel.reflect_on_association(:work_logs)).not_to be_nil
  end
  it 'should has many users' do
    expect(AccessLevel.reflect_on_association(:users)).not_to be_nil
  end
  it 'should validates presence of name' do
    access_level=AccessLevel.new
    expect(access_level).not_to be_valid
    expect(access_level.errors.get(:name).first).to eq("can't be blank")
  end
  it "should have AccessLevel in database with id 1 and name 'customer'" do
    skip("this is needed for users and worklogs in real database , but we can't test it here")
    expect(AccessLevel.find(1).name).to eq('customer')
  end
end

# == Schema Information
#
# Table name: access_levels
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

