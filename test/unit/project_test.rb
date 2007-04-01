require File.dirname(__FILE__) + '/../test_helper'

class ProjectTest < Test::Unit::TestCase
  fixtures :projects

  def setup
    @project = Project.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Project,  @project
  end
end
