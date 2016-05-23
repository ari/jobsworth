require 'spec_helper'

describe NewsItemsController do
  render_views

  context "If the logged user is an admin" do
    before :each do
      sign_in_admin
    end

    describe "GET 'index'" do
      before :each do
        @news_item_1 = NewsItem.make(:company => @logged_user.company)
        @news_item_2 = NewsItem.make(:company => @logged_user.company)
      end

      it "should be successuful" do
        get :index
        expect(response).to be_success
      end

      it "should render the right template" do
        get :index
        expect(response).to render_template :index
      end

      it "should display a list of all the news items" do
        get :index
        expect(response.body).to match ERB::Util.h(@news_item_1.body)
        expect(response.body).to match ERB::Util.h(@news_item_2.body)
      end
    end

    describe "GET 'new'" do
      it "should be successful" do
        get :new
        expect(response).to be_success
      end

      it "should render the right template" do
        get :new
        expect(response).to render_template :new
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
          expect(response).to redirect_to news_items_path
        end

        it "should display a notification telling the user that the news was created" do
          post :create, :news => @valid_attr
          expect(flash[:success]).to match I18n.t('flash.notice.model_created', model: NewsItem.model_name.human)
        end
      end

      context "When using invalid attributes" do
        before :each do
          @invalid_attrs =  { :body => '', :portal => true }
        end

        it "should not create a new instance" do
          expect {
            post :create, :news => @invalid_attrs
          }.to_not change { NewsItem.count }
        end

        it "should re-render the 'new' template" do
          post :create, :news => @invalid_attrs
          expect(response).to render_template :new
        end
      end
    end

    describe "GET 'edit'" do
      before :each do
        @news = NewsItem.make(:company => @logged_user.company)
      end

      it "should be successful" do
        get :edit, :id => @news.id
        expect(response).to be_success
      end

      it "should render the right template" do
        get :edit, :id => @news.id
        expect(response).to render_template :edit
      end
    end

    describe "PUT 'update'" do
      before :each do
        @news = NewsItem.make(:company => @logged_user.company)
        @attrs = { :body => 'something', :portal => true }
      end

      it "should update the news attributes correctly" do
        put :update, :id => @news.id, :news => @attrs
        @news.reload
        expect(@news.body).to match @attrs[:body]
      end

      it "should redirect to the 'index' action" do
        put :update, :id => @news.id, :news => @attrs
        expect(response).to redirect_to news_items_path
      end

      it "should display a message telling the user the news was updated" do
        put :update, :id => @news.id, :news => @attrs
        expect(flash[:success]).to match I18n.t('flash.notice.model_updated', model: NewsItem.model_name.human)
      end
    end

    describe "DELETE 'destroy'" do
      before :each do
        @news = NewsItem.make(:company => @logged_user.company)
      end

      it "should delete the instance" do
        expect {
          delete :destroy, :id => @news.id
        }.to change { NewsItem.count }.by(-1)
      end

      it "should redirect to the 'index' action" do
        delete :destroy, :id => @news.id
        expect(response).to redirect_to news_items_path
      end

      it "should display a message telling the user the news was deleted" do
        delete :destroy, :id => @news.id
        expect(flash[:success]).to match I18n.t('flash.notice.model_deleted', model: NewsItem.model_name.human)
      end
    end
  end
end
