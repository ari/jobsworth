class Test::Spec::Should
  include ActionController::Assertions
  
  alias :_old_equal :equal
  def equal(*args)
    @object.respond_to?(:should_equal) ? @object.should_equal(*args) : _old_equal(*args)
  end

  alias :_old_be :be
  def be(*args)
    @object.respond_to?(:should_equal) ? @object.should_equal(*args) : _old_be(*args)
  end
  
  alias :have :be
end

class Test::Spec::ShouldNot
  include ActionController::Assertions
  
  alias :_old_equal :equal
  def equal(*args,&block)
    @object.respond_to?(:should_not_equal) ? @object.should_not_equal(*args,&block) : _old_equal(*args,&block)
  end

  alias :_old_be :be
  def be(*args,&block)
    @object.respond_to?(:should_not_equal) ? @object.should_not_equal(*args,&block) : _old_be(*args,&block)
  end
end
