require File.dirname(__FILE__) + '/../test_helper'

class ProjectTest < Test::Unit::TestCase
  fixtures :projects, :companies, :users, :customers

  def setup
    @project = projects(:test_project)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Project,  @project
  end
  
  def test_after_create_without_forum
    p = Project.new
    p.name = "a"
    p.owner = users(:admin)
    p.company = companies(:cit)
    p.customer = customers(:internal_customer)
    p.create_forum = 0
    p.save
    
    assert_not_nil        p.forums
    assert_equal       0, p.forums.size
  end

  def test_after_create_with_forum
    p = Project.new
    p.name = "a"
    p.owner = users(:admin)
    p.company = companies(:cit)
    p.customer = customers(:internal_customer)
    p.create_forum = 1
    p.save

    assert_not_nil        p.forums
    assert_equal       1, p.forums.size
    assert_kind_of Forum, p.forums.first
    assert_equal     "Internal / a", p.forums.first.name
  end


  def test_validate_name
    p = Project.new
    p.owner = users(:admin)
    p.company = companies(:cit)
    p.customer = customers(:internal_customer)

    assert !p.save
    assert_equal 1, p.errors.size
    assert_equal "can't be blank", p.errors['name']
    
  end
  
  def test_full_name
    assert_equal "Internal / Test Project", @project.full_name
  end
  
  def test_to_css_name
    assert_equal "test-project internal", @project.to_css_name
  end
  
end
