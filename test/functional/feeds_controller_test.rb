require 'test_helper'

class FeedsControllerTest < ActionController::TestCase
  signed_in_admin_context do
    def setup
      @request.host = 'cit.local.host'
      @user = User.make

      WorkLog.delete_all
      10.times { WorkLog.make(:user => @user, :company => @user.company) }
    end

    should 'render rss' do
      get :rss, { :id => @user.uuid }
      assert_response :success
    end

    should 'render ical' do
      get :ical, { :id => @user.uuid }
      assert_response :success
    end
  end
end
