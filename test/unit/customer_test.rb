require File.dirname(__FILE__) + '/../test_helper'

class CustomerTest < ActiveRecord::TestCase
  fixtures :companies, :customers

  should_have_many :task_customers, :dependent => :destroy
  should_have_many :tasks, :through => :task_customers
  should_have_many :notes

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

# == Schema Information
#
# Table name: customers
#
#  id            :integer(4)      not null, primary key
#  company_id    :integer(4)      default(0), not null
#  name          :string(200)     default(""), not null
#  contact_email :string(200)
#  contact_name  :string(200)
#  created_at    :datetime
#  updated_at    :datetime
#  css           :text
#  binary_id     :integer(4)
#  active        :boolean(1)      default(TRUE)
#

