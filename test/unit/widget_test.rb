require File.dirname(__FILE__) + '/../test_helper'

class WidgetTest < Test::Unit::TestCase
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
    assert_equal "can't be blank", w.errors['name']

  end


end
