require File.dirname(__FILE__) + '/../test_helper'

class CompanyTest < Test::Unit::TestCase
  fixtures :companies, :customers

  def setup
    @company = companies(:cit)
  end

  def test_truth
    assert_kind_of Company,  @company
  end

  def test_internal_customer
#    @company.internal_customer.id.should.be 1
    @company.internal_customer.name.should.equal "Internal"
  end

  def test_subdomain_uniqueness
    company = Company.new
    company.name = "Test"
    company.subdomain = 'cit'
    
    company.should.not.validate
    company.errors.on(:subdomain).should.not.be.blank
    
    company.subdomain = 'unique-name'
    company.should.validate
    company.errors.on(:subdomain).should.be.blank
  end

  def test_company_should_create_default_properties_on_create
    c = Company.new(:name => "test", :subdomain => "test")
    assert c.save

    type = c.properties.find_by_name("Type")
    assert_not_nil type
    assert_equal 4, type.property_values.length

    severity = c.properties.find_by_name("Severity")
    assert_not_nil severity
    assert_equal 6, severity.property_values.length

    priority = c.properties.find_by_name("Priority")
    assert_not_nil priority
    assert_equal 6, priority.property_values.length
  end

end
