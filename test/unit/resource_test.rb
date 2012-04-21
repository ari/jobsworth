require "test_helper"

class ResourceTest < ActiveRecord::TestCase
  fixtures :companies, :customers

  def setup
    company = Company.find(:first)
    @type = company.resource_types.build(:name => "test")
    @type.new_type_attributes = [ { :name => "a1" }, { :name => "a2" } ]
    @type.save!

    customer = company.customers.build(:name => "test cust")
    customer.save!

    @resource = company.resources.build(:name => "test res")
    @resource.resource_type = @type
    @resource.customer = customer
  end

  def test_attribute_values_creates_new_attributes
    params = []
    params << {
      :resource_type_attribute_id => @type.resource_type_attributes.first.id,
      :value => "t1" }
    params << {
      :resource_type_attribute_id => @type.resource_type_attributes[1].id,
      :value => "t2" }

    @resource.attribute_values = params
    attrs = @resource.resource_attributes
    assert_equal 2, attrs.length
    assert_equal "t1", attrs.first.value
    assert_equal "t2", attrs[1].value
  end

  def test_attribute_values_updates_existing_attributes
    @resource.resource_attributes.build(:resource_type_attribute_id => @type.id,
                                        :value => "t1")
    @resource.save!

    assert_equal 1, @resource.resource_attributes.length
    attr = @resource.resource_attributes.first
    assert_equal "t1", attr.value

    params = [ { :id => attr.id, :value => "T2" } ]
    @resource.attribute_values = params

    assert_equal 1, @resource.resource_attributes.length
    new_attr = @resource.resource_attributes.first
    assert_equal attr.id, new_attr.id
    assert_equal "T2", new_attr.value
  end

  def test_not_valid_if_mandatory_fields_missing
    assert @resource.valid?

    attr = @type.resource_type_attributes.first

    attr.is_mandatory = true
    @type.save

    assert !@resource.valid?
  end

  def test_validate_attributes_does_not_fail_when_resource_type_not_set
    @resource.resource_type = nil

    begin
      assert @resource.validate_attributes
    rescue
      assert_equal "", "Shouldn't throw an error"
    end
  end

  def test_customer_is_required
    customer = @resource.customer
    assert @resource.valid?

    @resource.customer = nil
    assert !@resource.valid?

    @resource.customer = customer
    assert @resource.valid?
  end
end






# == Schema Information
#
# Table name: resources
#
#  id               :integer(4)      not null, primary key
#  company_id       :integer(4)
#  resource_type_id :integer(4)
#  parent_id        :integer(4)
#  name             :string(255)
#  customer_id      :integer(4)
#  notes            :text
#  created_at       :datetime
#  updated_at       :datetime
#  active           :boolean(1)      default(TRUE)
#
# Indexes
#
#  fk_resources_company_id  (company_id)
#

