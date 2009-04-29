require File.dirname(__FILE__) + '/../test_helper'

class OrganizationalUnitTest < ActiveRecord::TestCase
  def test_requires_name
    ou = OrganizationalUnit.new

    assert !ou.valid?
    ou.name = "AA"
    assert ou.valid?
  end
end
