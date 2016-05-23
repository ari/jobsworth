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
        expect(response).to redirect_to root_path
      end

      it "should display a notificiation" do
        get :index
        expect(flash[:alert]).to have_content I18n.t('flash.alert.admin_permission_needed')
      end
    end

    context "If the logged user is an admin" do
      before :each do
        sign_in_admin
      end

      it "should allow the user to procced to the desired action" do
        get :index
        expect(response).to render_template :index
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
        expect(response).to be_success
      end
    end
  end
end
