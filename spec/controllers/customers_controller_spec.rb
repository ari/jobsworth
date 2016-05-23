require 'spec_helper'

describe CustomersController do
  render_views

  describe 'contact creation disabled in the app' do
    before :each do
        Setting.contact_creation_allowed = false
        sign_in_admin
    end

    context "When trying to create a new customer" do
      before :each do
        @logged_user.update_column(:create_clients, false)
      end

      it "should redirect to the root_path" do
        get :new
        expect(response).to redirect_to root_path
      end

      it "should indicated the user that access is denied" do
        get :new
        expect(flash[:error]).to match 'Access denied'
      end
    end

    context "When trying to edit a customer" do
      before :each do
        @logged_user.update_column(:edit_clients, false)
        @customer = Customer.make(:company => @logged_user.company)
      end

      it "should redirect to the root_path" do
        get :edit, :id => @customer.id
        expect(response).to be_ok
      end
    end
  end

  describe "Filters" do
    context "When the logged user is an admin" do
      before :each do
        Setting.contact_creation_allowed = true
        sign_in_admin
      end

      it "should be able to view a single customer" do
        customer = Customer.make(:company => @logged_user.company)
        get :show, :id => customer.id
        expect(response).to be_success
      end

      it "should be able to create a new customer" do
        get :new
        expect(response).to be_success
      end

      it "should be able to edit a customer" do
        customer = Customer.make(:company => @logged_user.company)
        get :edit, :id => customer.id
        expect(response).to be_success
      end

      it "should be able to delete a customer" do
        customer = Customer.make(:company => @logged_user.company)
        delete :destroy, :id => customer.id
        expect(response).to redirect_to root_path
      end
    end

    context "When the logged user is not and admin" do
      before :each do
        sign_in_normal_user(seen_welcome: 1)
      end

      context "When trying to read customers and the user is not authorized to do so" do
        before :each do
          @logged_user.update_column(:read_clients, false)
        end
      end

      context "When trying to read customers and the user is authorized to do so" do
        before :each do
          @logged_user.update_column(:read_clients, true)
        end
      end

      context "When trying to create a new customer and the user is not authorized to do so" do
        before :each do
          @logged_user.update_column(:create_clients, false)
        end

        it "should redirect to the root_path" do
          get :new
          expect(response).to redirect_to root_path
        end

        it "should indicated the user that access is denied" do
          get :new
          expect(flash[:error]).to match 'Access denied'
        end
      end

      context "When trying to create a new customer and the user is authorized to do so" do
        before :each do
          @logged_user.update_column(:create_clients, true)
        end

        it "should allow the access" do
          get :new
          expect(response).to be_success
        end
      end

      context "When trying to edit a customer and the user is not authorized to do so" do
        before :each do
          @logged_user.update_column(:edit_clients, false)
          @customer = Customer.make(:company => @logged_user.company)
        end

        it "should redirect to the root_path" do
          get :edit, :id => @customer.id
          expect(response).to redirect_to root_path
        end

        it "should indicated the user that access is denied" do
          get :edit, :id => @customer.id
          expect(flash[:error]).to match 'Access denied'
        end
      end

      context "When trying to edit a customer and the user is authorized to do so" do
        before :each do
          @logged_user.update_column(:edit_clients, true)
          @customer = Customer.make(:company => @logged_user.company)
        end

        it "should allow the access" do
          get :edit, :id => @customer.id
          expect(response).to be_success
        end
      end
    end
  end

  describe "GET 'show'" do
    context "When the logged user is authorized" do
      before :each do
        Setting.contact_creation_allowed = true
        sign_in_admin
        allow(@logged_user).to receive(:read_clients?).and_return(true)
        @some_customer = Customer.make(:company => @logged_user.company)
      end

      it "should be succesful" do
        get :show, :id => @some_customer.id
        expect(response).to be_success
      end

      it "should render the right template" do
        get :show, :id => @some_customer.id
        expect(response).to render_template :show
      end
    end
  end

  describe "GET 'new'" do
    context "When the logged user is authorized" do
      before :each do
        Setting.contact_creation_allowed = true
        sign_in_admin
        allow(@logged_user).to receive(:create_clients?).and_return(true)
      end

      it "should be successful" do
        get :new
        expect(response).to be_success
      end

      it "should render the right template" do
        get :new
        expect(response).to render_template :new
      end
    end
  end

  describe "POST 'create'" do
    context "When the logged user is authorized" do
      before :each do
        Setting.contact_creation_allowed = true
        sign_in_admin
        allow(@logged_user).to receive(:create_clients?).and_return(true)
      end

      context "When using valid attributes" do
        before :each do
          company_id = @logged_user.company_id
          @valid_attributes = { :name => 'Lol', :company_id => company_id }
        end

        it "should be create a new customer instance" do
          expect {
            post :create, :customer => @valid_attributes
          }.to change { Customer.count }.by(1)
        end

        it "should notify the user that the customer was created" do
          post :create, :customer => @valid_attributes
          expect(flash[:notice]).to have_content I18n.t('flash.notice.model_created', model: Customer.model_name.human)
        end

        it "should redirect to the root" do
          post :create, :customer => @valid_attributes
          expect(response).to redirect_to root_path
        end
      end

      context "When using invalid attributes" do
        before :each do
          company_id = @logged_user.company_id
          @invalid_attributes = { :name => '', :company_id => company_id }
        end

        it "should render the 'new' template" do
          post :create, :customer => @invalid_attributes
          expect(response).to render_template :new
        end
      end
    end
  end

  describe "GET 'edit'" do
    context "When the logged user is authorized" do
      before :each do
        Setting.contact_creation_allowed = true
        sign_in_admin
        allow(@logged_user).to receive(:edit_clients?).and_return(true)
        @some_customer = Customer.make(:company => @logged_user.company)
      end

      it "should be successful" do
        get :edit, :id => @some_customer
        expect(response).to be_success
      end

      it "should render the right template" do
        get :edit, :id => @some_customer
        expect(response).to render_template :edit
      end
    end
  end

  describe "PUT 'update'" do
    context "When the logged user is authorized" do
      before :each do
        Setting.contact_creation_allowed = true
        sign_in_admin
        allow(@logged_user).to receive(:edit_clients?).and_return(true)
        @some_customer = Customer.make(:company => @logged_user.company)
      end

      context "When using valid attributes" do
        before :each do
          @valid_attributes = { :name => 'new_name' }
        end

        it "shoud update the customer record successfully" do
          put :update, :id => @some_customer, :customer => @valid_attributes
          @some_customer.reload
          expect(@some_customer.name).to match @valid_attributes[:name]
        end

        it "should redirect to the 'edit' action" do
          put :update, :id => @some_customer, :customer => @valid_attributes
          expect(response).to redirect_to "/customers/#{@some_customer.id}/edit"
        end

        it "should tell the user that the customer was updated" do
          put :update, :id => @some_customer, :customer => @valid_attributes
          expect(flash[:success]).to have_content I18n.t('flash.notice.model_updated', model: Customer.model_name.human)
        end
      end

      context "When using invalid attributes" do
        it "should render the 'edit' view" do
          put :update, :id => @some_customer, :customer => { :name => '' }
          expect(response).to render_template :edit
        end
      end
    end
  end

  describe "DELETE 'destroy'" do
    context "When the logged user is authorized" do
      before :each do
        Setting.contact_creation_allowed = true
        sign_in_admin
        allow(@logged_user).to receive(:edit_clients?).and_return(true)
        @some_customer = Customer.make(:company => @logged_user.company, :name => 'Juan')
      end

      context "When the customer doesn't have projects and it's not the internal_customer" do
        it "should be able to delete the customer instance" do
          expect {
            delete :destroy, :id => @some_customer
          }.to change { Customer.count }.by(-1)
        end

        it "should redirect to the root" do
          delete :destroy, :id => @some_customer
          expect(response).to redirect_to root_path
        end

        it "should tell the user that the customer was deleted" do
          delete :destroy, :id => @some_customer
          expect(flash[:success]).to have_content I18n.t('flash.notice.model_deleted', model: Customer.model_name.human)
        end
      end

      context "When the customer have projects" do
        before :each do
          @some_customer.projects << Project.make
        end

        it "should not be able to delete the instance" do
          expect {
            delete :destroy, :id => @some_customer
          }.to_not change { Customer.count }
        end

        it "should tell the user that it can't delete the customer" do
          delete :destroy, :id => @some_customer
          msg = I18n.t('flash.error.destroy_dependents_of_model',
                        dependents: @some_customer.human_name(:projects),
                        model: @some_customer.name)
          expect(flash[:error]).to have_content msg
        end

        it "should redirect to the root" do
          delete :destroy, :id => @some_customer
          expect(response).to redirect_to root_path
        end
      end

      context "When the customer it's the internal customer of the company" do
        before :each do
          @some_customer.name = @some_customer.company.name
          @some_customer.save
        end

        it "should not be able to delete the instance" do
          expect {
            delete :destroy, :id => @some_customer
          }.to_not change { Customer.count }
        end

        it "should tell the user that it can't delete the customer" do
          delete :destroy, :id => @some_customer
          expect(flash[:error]).to match "You can't delete your own company."
        end

        it "should redirect to the root" do
          delete :destroy, :id => @some_customer
          expect(response).to redirect_to root_path
        end
      end
    end
  end

  describe "POST 'search'" do
    before :each do
      Setting.contact_creation_allowed = true
      sign_in_normal_user

      @customer_one   = Customer.make(:name => 'Juan', :company => @logged_user.company)
      @customer_two   = Customer.make(:name => 'Omar', :company => @logged_user.company)
    end

    it "should fetch the right customers based on the provided search criteria" do
      get :search, :term => @customer_one.name
      expect(response.body).to match ERB::Util.h(@customer_one.name)
      get :search, :term => @customer_two.name
      expect(response.body).to match ERB::Util.h(@customer_two.name)
    end
  end
end
