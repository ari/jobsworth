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
  
    describe "GET 'new'" do
      it "should be successful" do
        get :new
        response.should be_success
      end

      it "should render the right template" do
        get :new
        response.should render_template :new
      end
    end

    describe "POST 'create'" do
      context "When using valid attributes" do
        before :each do
          @valid_attr = { :body => 'Lololol', :portal => true }
        end

        it "should create a new instance" do
          expect {
            post :create, :news => @valid_attr
          }.to change { NewsItem.count }
        end

        it "should redirect to the 'index' action" do
          post :create, :news => @valid_attr
          response.should redirect_to news_items_path
        end

        it "should display a notification telling the user that the news was created" do
          post :create, :news => @valid_attr
          flash[:success].should match 'NewsItem was successfully created.'
        end
      end

      context "When using invalid attributes" do
        before :each do
          @invalid_attr =  { :body => '', :portal => true }
        end

        it "should not create a new instance" do
          expect {
            post :create, :news => @invalid_attrs
          }.to_not change { NewsItem.count }
        end

        it "should re-render the 'new' template" do
          post :create, :news => @invalid_attrs
          response.should render_template :new
        end
      end
    end

    describe "GET 'edit'" do
      before :each do
        @news = NewsItem.make
      end

      it "should be successful" do
        get :edit, :id => @news.id
        response.should be_success
      end

      it "should render the right template" do
        get :edit, :id => @news.id
        response.should render_template :edit
      end
    end

    describe "PUT 'update'" do
      before :each do
        @news = NewsItem.make
        @attrs = { :body => 'something', :portal => true }
      end
      
      it "should update the news attributes correctly" do
        put :update, :id => @news.id, :news => @attrs  
        @news.reload
        @news.body.should match @attrs[:body]
      end

      it "should redirect to the 'index' action" do
        put :update, :id => @news.id, :news => @attrs  
        response.should redirect_to news_items_path 
      end

      it "should display a message telling the user the news was updated" do
        put :update, :id => @news.id, :news => @attrs  
        flash[:success].should match 'NewsItem was successfully updated.'
      end
    end

    describe "DELETE 'destroy'" do
      before :each do
        @news = NewsItem.make
      end

      it "should delete the instance" do
        expect {
          delete :destroy, :id => @news.id
        }.to change { NewsItem.count }.by(-1) 
      end

      it "should redirect to the 'index' action" do
        delete :destroy, :id => @news.id
        response.should redirect_to news_items_path 
      end

      it "should display a message telling the user the news was deleted" do
        delete :destroy, :id => @news.id
        flash[:success].should match 'NewsItem was successfully deleted.'
      end
    end
  end
end
