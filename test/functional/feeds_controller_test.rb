require File.dirname(__FILE__) + '/../test_helper'

class FeedsControllerTest < ActionController::TestCase
  fixtures :users
  
  def setup 
    use_controller FeedsController
    @request.host = 'cit.local.host'
  end
  
  test "should not redirect to login" do
    get :rss, { :id => '1234567890abcdefghijklmnopqrstuv'}
  end 
end

class FeedUsersControllerTest < ActionController::TestCase
  fixtures :users
  
  def setup
    use_controller FeedsController
    @request.host = 'cit.local.host'
  end 
  
  test "should be able to unsubscribe" do 
    user = User.find_by_uuid('1234567890abcdefghijklmnopqrstuv')
    user.newsletter.should.equal 1
    get :unsubscribe, { :id => '1234567890abcdefghijklmnopqrstuv'}
    unsubbed = User.find_by_uuid('1234567890abcdefghijklmnopqrstuv')
    unsubbed.newsletter.should.equal 0
    status.should.be :success
    body.should.include 'unsubscribed'
  end

#   xtest "should get RSS"
  
#   xtest "should get iCal"
  
#   xtest "should get iGoogle widget"
end 
