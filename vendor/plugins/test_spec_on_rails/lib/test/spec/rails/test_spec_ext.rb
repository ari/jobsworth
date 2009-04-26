class Test::Spec::Should
  include Test::Unit::Assertions
  
  if defined?(ActionController::TestCase::Assertions)
    include ActionController::TestCase::Assertions
  end
  
  alias :_old_equal :equal
  def equal(*args)
    @object.respond_to?(:should_equal) ? @object.should_equal(*args) : _old_equal(*args)
  end

  alias :_old_be :be
  def be(*args)
    @object.respond_to?(:should_equal) ? @object.should_equal(*args) : _old_be(*args)
  end
  
  alias :have :be
  
  def differ(method)
    @initial_value = @object.send(@method = method)
    self
  end

  def by(value)
    yield
    # TODO: this should use should_equal if available
    assert_equal @initial_value + value, @object.send(@method)
  end
end

class Test::Spec::ShouldNot
  include Test::Unit::Assertions
  
  if defined?(ActionController::TestCase::Assertions)
    include ActionController::TestCase::Assertions
  end
  
  alias :_old_equal :equal
  def equal(*args,&block)
    @object.respond_to?(:should_not_equal) ? @object.should_not_equal(*args,&block) : _old_equal(*args,&block)
  end

  alias :_old_be :be
  def be(*args,&block)
    @object.respond_to?(:should_not_equal) ? @object.should_not_equal(*args,&block) : _old_be(*args,&block)
  end
end
