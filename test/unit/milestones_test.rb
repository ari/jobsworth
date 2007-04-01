require File.dirname(__FILE__) + '/../test_helper'

class MilestonesTest < Test::Unit::TestCase
  fixtures :milestones

  def setup
    @milestones = Milestones.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Milestones,  @milestones
  end
end
