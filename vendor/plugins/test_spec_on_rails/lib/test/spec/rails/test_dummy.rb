# Base class for testcase/response/request/controller mocks
class Test::Spec::Rails::TestDummy
  include Test::Unit::Assertions
  include ActionController::Assertions

  def initialize(testcase)
    @controller = testcase.instance_variable_get('@controller')
    @request    = testcase.instance_variable_get('@request')
    @response   = testcase.instance_variable_get('@response')
  end
  
  def inspect
    "<#{self.class}:#{self.to_s}>"
  end
    
  def method_missing(method, *args, &block)
    if real_response.respond_to?(method)
      real_response.send(method, *args, &block)
    elsif real_request.respond_to?(method)
      real_request.send(method, *args, &block)
    elsif real_controller.respond_to?(method)
      real_controller.send(method, *args, &block)
    else
      super
    end
  end

  def real_response
    @response unless @response == self
  end
  def real_request
    @request unless @request == self
  end
  def real_controller
    @controller unless @controller == self
  end

end
