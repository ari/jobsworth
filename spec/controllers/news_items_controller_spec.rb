require 'spec_helper'

describe NewsItemsController do
  context "If the logged user is an admin" do
    before :each do
      sign_in_admin
    end

    describe "GET 'index'" do
      it "should be successuful" do
        get :index
        response.should be_success
      end

      it "should render the right template" do
        get :index
        response.should render_template :index
      end
    end
  end
end
