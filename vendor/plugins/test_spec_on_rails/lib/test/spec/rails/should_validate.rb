module Test::Spec::Rails::ShouldValidate
  def validate
    assert_valid @object
  end
  alias :validated :validate
end

module Test::Spec::Rails::ShouldNotValidate
  def validate
    assert !@object.valid?
  end
  alias :validated :validate
end

Test::Spec::Should.send(:include, Test::Spec::Rails::ShouldValidate)
Test::Spec::ShouldNot.send(:include, Test::Spec::Rails::ShouldNotValidate)
