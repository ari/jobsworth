require 'spec_helper'

describe ActivitiesController do
  render_views

  describe "GET 'index'" do
    context "When the user is signed in" do
      before :each do
        sign_in_normal_user
      end

      it "should be successful" do
        get :index
        response.should be_success
      end

      it "should render the right template" do
        get :index
        response.should render_template 'index'
      end
    end
  end

  describe "GET 'hide_welcome'" do
    context "When the user is signed in" do
      before :each do
        sign_in_normal_user
      end

      it "should update the 'seen_welcome' flag on the logged user" do
        get :hide_welcome
        @logged_user.reload
        @logged_user.seen_welcome.should == 1  
      end

      it "should display a notification message" do
        get :hide_welcome
        flash['notice'].should match 'Tutorial hidden. It will no longer be shown in the menu.'
      end

      it "should redirect to the 'index' action" do
        get :hide_welcome
        response.should redirect_to root_path
      end
    end
  end
end
