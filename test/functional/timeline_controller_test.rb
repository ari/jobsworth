require File.dirname(__FILE__) + '/../test_helper'
require 'timeline_controller'

# Re-raise errors caught by the controller.
class TimelineController; def rescue_action(e) raise e end; end

class TimelineControllerTest < Test::Unit::TestCase
  def setup
    @controller = TimelineController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
