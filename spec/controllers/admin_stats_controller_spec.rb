require 'spec_helper'

describe AdminStatsController do
  render_views

  describe "Authorization" do
    context "If the logged user is not an Admin" do
      before :each do
        sign_in_normal_user
      end

      it "should redirect to the root path" do
        get :index
        response.should redirect_to root_path
      end

      it "should display a notificiation" do
        get :index
        flash[:error].should match 'Only admins may access this area.'
      end
    end 

    context "If the logged user is an admin" do
      before :each do
        sign_in_admin
      end

      it "should allow the user to procced to the desired action" do
        get :index
        response.should render_template :index
      end
    end
  end

  describe "GET 'index'" do
    context "When the logged user is an admin" do
      before :each do
        sign_in_admin
      end

      it "should be successful" do
        get :index
        response.should be_success
      end
    end
  end
end
