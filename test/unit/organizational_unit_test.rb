require File.dirname(__FILE__) + '/../test_helper'

class OrganizationalUnitTest < ActiveRecord::TestCase
  context "a normal org unit" do
    setup do
      @org_unit = OrganizationalUnit.make
      @org_unit.save!
    end
    subject { @org_unit }

    should_validate_presence_of :name
    should_belong_to :customer
    should_have_many :custom_attribute_values
  end
end

# == Schema Information
#
# Table name: organizational_units
#
#  id          :integer(4)      not null, primary key
#  customer_id :integer(4)
#  created_at  :datetime
#  updated_at  :datetime
#  name        :string(255)
#  active      :boolean(1)      default(TRUE)
#

