require 'spec_helper'

describe NewsItemsController do
  render_views

  context "If the logged user is an admin" do
    before :each do
      sign_in_admin
    end

    describe "GET 'index'" do
      before :each do
        @news_item_1 = NewsItem.make
        @news_item_2 = NewsItem.make
      end

      it "should be successuful" do
        get :index
        response.should be_success
      end

      it "should render the right template" do
        get :index
        response.should render_template :index
      end

      it "should display a list of all the news items" do
        get :index
        response.body.should match @news_item_1.body
        response.body.should match @news_item_2.body
      end
    end
  end
end
