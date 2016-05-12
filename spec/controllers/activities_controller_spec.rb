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
        expect(response).to be_success
      end

      it "should render the right template" do
        get :index
        expect(response).to render_template 'index'
      end
    end
  end
end
