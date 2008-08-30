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

end
