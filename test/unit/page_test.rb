require File.dirname(__FILE__) + '/../test_helper'

class PageTest < Test::Unit::TestCase
  fixtures :pages

  def setup
    @page = Page.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Page,  @page
  end
end
