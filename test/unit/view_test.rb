require File.dirname(__FILE__) + '/../test_helper'

class ViewTest < ActiveRecord::TestCase
  fixtures :companies
  def setup
    company = companies(:cit)
    @type, @priority, @severity = company.create_default_properties
    user = company.users.first
    
    @view = View.new(:name => "test", :user_id => user.id, :company_id => company.id)
    @view.save!
  end

  def test_properties_setter_clears_old_values
    pv1 = @view.company.properties.first.property_values.first
    pv2 = @view.company.properties.first.property_values.last
    assert_not_nil pv1
    assert_not_nil pv2

    @view.property_values << pv1
    assert_equal 1, @view.property_values.length

    @view.properties = [ pv2.id ]
    assert_equal 1, @view.property_values.length
    assert_equal pv2, @view.property_values.first
  end

  def test_selected_returns_value_for_correct_property
    p1 = @view.company.properties.first
    assert_not_nil p1

    assert_nil @view.selected(p1)
    @view.property_values << p1.property_values.first
    assert_equal p1.property_values.first, @view.selected(p1)
  end

  def test_convert_to_properties_works
    @view.filter_type_id = 2
    @view.filter_severity = -1
    @view.filter_priority = 3
    
    @view.convert_attributes_to_properties
    assert_equal 2, @view.filter_type_id
    
    assert_equal "Defect", @view.selected(@type).to_s
    assert_equal "Minor", @view.selected(@severity).to_s
    assert_equal "Critical", @view.selected(@priority).to_s

    @view.filter_type_id = -1
    @view.convert_attributes_to_properties
    assert_nil @view.selected(@type)
  end


  def test_convert_properties_to_attributes
    pvs = []
    pvs << @type.property_values.last
    pvs << @severity.property_values[2]

    @view.properties = pvs.map { |pv| pv.id.to_s }
    @view.convert_properties_to_attributes

    assert_equal 3, @view.filter_type_id
    assert_equal 1, @view.filter_severity
    assert_equal -10, @view.filter_priority
  end
end

# == Schema Information
#
# Table name: views
#
#  id                  :integer(4)      not null, primary key
#  name                :string(255)
#  company_id          :integer(4)
#  user_id             :integer(4)
#  shared              :integer(4)      default(0)
#  auto_group          :string(255)     default("0")
#  filter_customer_id  :string(255)     default("0")
#  filter_project_id   :string(255)     default("0")
#  filter_milestone_id :string(255)     default("0")
#  filter_user_id      :string(255)     default("0")
#  filter_tags         :string(255)     default("")
#  filter_status       :string(255)     default("0")
#  filter_type_id      :integer(4)      default(0)
#  hide_deferred       :integer(4)
#  sort                :integer(4)      default(0)
#  filter_severity     :integer(4)      default(-10)
#  filter_priority     :integer(4)      default(-10)
#  hide_dependencies   :integer(4)
#  colors              :integer(4)
#  icons               :integer(4)
#  show_all_unread     :boolean(1)      default(FALSE)
#

