require File.dirname(__FILE__) + '/../test_helper'

class CustomerTest < Test::Unit::TestCase
  fixtures :companies, :customers

  def setup
    @internal = Customer.find(1)
    @external = Customer.find(2)
  end

  def test_truth
    assert_kind_of Customer,  @internal
  end
  
  def test_path
    assert_equal File.join("#{RAILS_ROOT}", 'store', 'logos', '1'), @internal.path
  end

  def test_store_name
    assert_equal "logo_1", @internal.store_name
  end

  def test_logo_path
    assert_equal File.join("#{RAILS_ROOT}", 'store', 'logos', '1', 'logo_1'), @internal.logo_path
  end
  
  def test_full_name
    assert_equal "ClockingIT", @internal.full_name
    assert_not_equal "ClockingIT", @external.full_name
  end
  
end
