require File.dirname(__FILE__) + '/../test_helper'

class CustomerTest < Test::Unit::TestCase
  fixtures :customers

  def setup
    @customer = Customer.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Customer,  @customer
  end
end
