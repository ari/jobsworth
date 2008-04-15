module Test::Spec::Rails::ShouldSelect
  # Wrapper for +assert_select+. Examples:
  #
  # Test that the previous request has a login form:
  #   page.should.select "form#login"
  #
  # Test that a specific form has a field pre-filled (this is specific test/spec/rails):
  #   page.should.select "form#login" do |form|
  #     form.should.select "input[name=user_nick]", :text => @user.nick
  #   end
  #
  # See the Rails API documentation for assert_select for more information
  def select(selector, equality=true, message=nil, &block)
    @@response_stack ||= []
    
    if @object.is_a?(Test::Unit::TestCase)
      @@response_stack.push(Test::Spec::Rails::DummyResponse.new(@object))
      
    elsif @object.is_a?(Array) && @object.first.is_a?(HTML::Tag)
      @@response_stack.push(Test::Spec::Rails::DummyResponse.new(
        @object.first.to_s, @@response_stack.last.headers
      ))
    else
      @@response_stack.push(Test::Spec::Rails::DummyResponse.new(@object.to_s,
        (@@response_stack.last.headers rescue 'Content-Type: text/html; charset=utf8')
      ))
    end
    
    @@response_stack.last.assert_select(selector, equality, message, &block)
    @@response_stack.pop
  end
end

module Test::Spec::Rails::ShouldNotSelect
  include Test::Spec::Rails::ShouldSelect
  def select(selector, message=nil, &block)
    super(selector, false, message, &block)
  end
end

Test::Spec::Should.send(:include, Test::Spec::Rails::ShouldSelect)
Test::Spec::ShouldNot.send(:include, Test::Spec::Rails::ShouldNotSelect)
