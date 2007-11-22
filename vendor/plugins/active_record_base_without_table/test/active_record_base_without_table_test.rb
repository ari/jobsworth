require File.dirname(__FILE__) + '/abstract_unit'

class Person < ActiveRecord::BaseWithoutTable
  column :name, :string
  column :lucky_number, :integer, 4
  
  validates_presence_of :name
end

class ActiveRecordBaseWithoutTableTest < Test::Unit::TestCase
  def test_default_value
    assert_equal 4, Person.new.lucky_number
  end
  
  def test_validation
    p = Person.new
    
    assert !p.save
    assert p.errors[:name]
    
    assert p.update_attributes(:name => 'Name')
  end
  
  def test_typecast
    assert_equal 1, Person.new(:lucky_number => "1").lucky_number
  end
  
  def test_cached_column_variables_reset_when_column_defined
    cached_variables = %w(column_names columns_hash content_columns dynamic_methods_hash read_methods)
    
    Person.column_names
    Person.columns_hash
    Person.content_columns
    Person.column_methods_hash
    Person.read_methods
    
    cached_variables.each { |v| assert_not_nil Person.instance_variable_get("@#{v}") }
    Person.column :new_column, :string
    cached_variables.each { |v| assert_nil Person.instance_variable_get("@#{v}") }
  end
end
