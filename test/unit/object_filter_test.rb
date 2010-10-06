require "test_helper"

class ObjectFilterTest < ActiveRecord::TestCase
  fixtures :tasks

  def setup
    @filter = ObjectFilter.new
  end

  def test_filter_with_no_params_returns_all_objects
    tasks = Task.find(:all)
    assert_equal tasks, @filter.filter(tasks)
  end

  def test_filter_on_object_with_no_filterable_returns_all
    strings = [ "a", "b", "cd" ]
    filtered = @filter.filter(strings, { :length => 1 })

    assert_equal filtered, strings
  end

  def test_filter_on_an_correct_object
    objects = test_objects

    assert_equal 3, @filter.filter(objects).length

    filtered = @filter.filter(objects, { :name => "a 0" })
    assert_equal 1, filtered.length

    filtered = @filter.filter(objects, { :name => "a" })
    assert_equal 0, filtered.length

    filtered = @filter.filter(objects, { :prop => "b" })
    assert_equal 2, filtered.length

    filtered = @filter.filter(objects, { :name => "a 1", :prop => "b" })
    assert_equal 1, filtered.length

    filtered = @filter.filter(objects, { :name => [ "a 0", "a 1" ] })
    assert_equal 2, filtered.length
  end

  private

  def test_objects
    objects = []
    2.times do |i|
      o = TestObj.new
      o.name = "a #{ i }"
      o.prop = "b"
      objects << o
    end

    o = TestObj.new
    o.name = "odd one out"
    o.prop = "odd one out"
    objects << o
    
    return objects
  end

end

class TestObj
  FILTERABLE = [ :name, :prop ]

  attr_accessor :name
  attr_accessor :prop
end
