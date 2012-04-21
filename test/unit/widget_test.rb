require "test_helper"

class WidgetTest < ActiveRecord::TestCase
  fixtures :users, :tasks, :widgets

  def setup
    @user = users(:admin)
  end

  # Replace this with your real tests.
  def test_truth
    @widget = @user.widgets.first
    assert_kind_of Widget,  @widget
  end

  def test_validate_name
    w = Widget.new

    assert !w.save
    assert_equal 1, w.errors.size
    assert_equal "can't be blank", w.errors['name'].first

  end


end







# == Schema Information
#
# Table name: widgets
#
#  id          :integer(4)      not null, primary key
#  company_id  :integer(4)
#  user_id     :integer(4)
#  name        :string(255)
#  widget_type :integer(4)      default(0)
#  number      :integer(4)      default(5)
#  mine        :boolean(1)
#  order_by    :string(255)
#  group_by    :string(255)
#  filter_by   :string(255)
#  collapsed   :boolean(1)      default(FALSE)
#  column      :integer(4)      default(0)
#  position    :integer(4)      default(0)
#  configured  :boolean(1)      default(FALSE)
#  created_at  :datetime
#  updated_at  :datetime
#  gadget_url  :text
#
# Indexes
#
#  fk_widgets_company_id     (company_id)
#  index_widgets_on_user_id  (user_id)
#

