require File.dirname(__FILE__) + '/../test_helper'

context "Feeds" do
  fixtures :users
  
  setup do 
    use_controller FeedsController
    @request.host = 'cit.local.host'
  end
  
  specify "should not redirect to login" do
    get :rss, { :id => '1234567890abcdefghijklmnopqrstuv'}
  end 
end

context "A feed user" do
  fixtures :users
  
  setup do
    use_controller FeedsController
    @request.host = 'cit.local.host'
  end 
  
  specify "should be able to unsubscribe" do 
    user = User.find_by_uuid('1234567890abcdefghijklmnopqrstuv')
    user.newsletter.should.equal 1
    get :unsubscribe, { :id => '1234567890abcdefghijklmnopqrstuv'}
    unsubbed = User.find_by_uuid('1234567890abcdefghijklmnopqrstuv')
    unsubbed.newsletter.should.equal 0
    status.should.be :success
    body.should.include 'unsubscribed'
  end

  xspecify "should get RSS"
  
  xspecify "should get iCal"
  
  xspecify "should get iGoogle widget"
end 
