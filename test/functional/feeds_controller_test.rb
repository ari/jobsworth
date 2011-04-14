require "test_helper"

class FeedsControllerTest < ActionController::TestCase
  fixtures :all
signed_in_admin_context do
  def setup 
    @request.host = 'cit.local.host'
  end
  
  should "render rss" do
    user = User.first
    get :rss, { :id => user.uuid }
    assert_response :success
  end 

  should "render ical" do
    user = User.first
    get :ical, { :id => user.uuid }
    assert_response :success
  end 
  
  should "be able to unsubscribe" do
    user = User.find_by_uuid('1234567890abcdefghijklmnopqrstuv')
    assert_equal 1, user.newsletter
    get :unsubscribe, { :id => '1234567890abcdefghijklmnopqrstuv'}
    unsubbed = User.find_by_uuid('1234567890abcdefghijklmnopqrstuv')
    assert_equal 0, unsubbed.newsletter
    assert_response :success
    assert @response.body.index("unsubscribed")
  end
end
#   xtest "should get RSS"
  
#   xtest "should get iCal"
  
#   xtest "should get iGoogle widget"
end 
