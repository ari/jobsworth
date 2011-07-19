require 'spec_helper'

describe CustomersController do
  render_views

  describe "GET 'index'" do
    context "When the logged user is an admin and has the right persmissions" do
      before :each do
        sign_in_admin
        @logged_user.stub!(:read_clients?).and_return(true)
      end

      it "should be successful" do
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
