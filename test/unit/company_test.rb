require File.dirname(__FILE__) + '/../test_helper'

class CompanyTest < Test::Unit::TestCase
  fixtures :companies

  def setup
    @company = Company.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Company,  @company
  end
end
