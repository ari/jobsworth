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
