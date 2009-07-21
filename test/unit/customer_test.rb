require File.dirname(__FILE__) + '/../test_helper'

class CustomerTest < ActiveRecord::TestCase
  fixtures :companies, :customers

  should_have_many :task_customers, :dependent => :destroy
  should_have_many :tasks, :through => :task_customers

  def setup
    @internal = customers(:internal_customer)
    @external = customers(:external_customer)
  end

  def test_path
    path = File.join("#{RAILS_ROOT}", 'store', 'logos', "#{@internal.company_id}")
    assert_equal path, @internal.path
  end

  def test_store_name
    assert_equal "logo_#{@internal.id}", @internal.store_name
  end

  def test_logo_path
    assert_equal File.join("#{RAILS_ROOT}", 'store', 'logos', "#{@internal.company_id}", "logo_#{@internal.id}"), @internal.logo_path
  end
  
  def test_full_name
    assert_equal "ClockingIT", @internal.full_name
    assert_not_equal "ClockingIT", @external.full_name
  end
  
end
