require "test_helper"

class ResourceTypeTest < ActiveRecord::TestCase
  fixtures :companies
  
  def setup
    @rt = Company.find(:first).resource_types.build
  end

  def test_new_attributes_creates_new_attributes
    params = []
    params << { :name => "a1" }
    params << { :name => "a2" }

    assert @rt.resource_type_attributes.empty?
    @rt.new_type_attributes = params
    assert_equal 2, @rt.resource_type_attributes.length
  end

  def test_attributes_update_existing_attributes
    a1, a2 = two_attributes
    params = {
      a1.id => { :name => "a1a" },
      a2.id => { :name => "a2a" }
    }
    @rt.type_attributes = params
    assert_equal "a1a",  @rt.resource_type_attributes.first.name
    assert_equal "a2a",  @rt.resource_type_attributes[1].name
  end

  def test_attributes_removes_attributes
    a1, a2 = two_attributes

    params = {
      a1.id => { :name => "a1a" }
    }
    @rt.type_attributes = params
    assert_equal "a1a",  @rt.resource_type_attributes.first.name
    assert_equal 1, @rt.resource_type_attributes.length
  end

  def test_attributes_sets_position
    a1, a2 = two_attributes
    
    params = {
      a1.id => { :name => "a1a", :position => 1 },
      a2.id => { :name => "a2a", :position => 0 }
    }
    @rt.type_attributes = params

    assert_equal 1, a1.position
    assert_equal 0, a2.position
  end

  private 

  def two_attributes
    @rt.save
    a1 = @rt.resource_type_attributes.build(:name => "a1")
    a1.save
    a2 = @rt.resource_type_attributes.build(:name => "a2")
    a2.save

    return a1, a2
  end

end






# == Schema Information
#
# Table name: resource_types
#
#  id         :integer(4)      not null, primary key
#  company_id :integer(4)
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  fk_resource_types_company_id  (company_id)
#

