require File.dirname(__FILE__) + '/../test_helper'

class SheetTest < Test::Unit::TestCase
  fixtures :sheets

  def setup
    @sheet = Sheet.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Sheet,  @sheet
  end
end
