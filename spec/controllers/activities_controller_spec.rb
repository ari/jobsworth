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
end
