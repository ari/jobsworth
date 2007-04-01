require File.dirname(__FILE__) + '/../test_helper'
require 'shout_controller'

# Re-raise errors caught by the controller.
class ShoutController; def rescue_action(e) raise e end; end

class ShoutControllerTest < Test::Unit::TestCase
  def setup
    @controller = ShoutController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
