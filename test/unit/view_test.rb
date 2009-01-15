require File.dirname(__FILE__) + '/../test_helper'

class ViewTest < Test::Unit::TestCase
  fixtures :companies
  def setup
    company = companies(:cit)
    company.create_default_properties
    user = company.users.first
    
    @view = View.new(:name => "test", :user_id => user.id, :company_id => company.id)
    @view.save!
  end

  def test_properties_setter_clears_old_values
    pv1 = Property.all_for_company(@view.company).first.property_values.first
    pv2 = Property.all_for_company(@view.company).first.property_values.last
    assert_not_nil pv1
    assert_not_nil pv2

    @view.property_values << pv1
    assert_equal 1, @view.property_values.length

    @view.properties = [ pv2.id ]
    assert_equal 1, @view.property_values.length
    assert_equal pv2, @view.property_values.first
  end

  def test_selected_returns_value_for_correct_property
    properties = Property.all_for_company(@view.company)
    p1 = properties.first
    assert_not_nil p1

    assert_nil @view.selected(p1)
    @view.property_values << p1.property_values.first
    assert_equal p1.property_values.first, @view.selected(p1)
  end

end
