require 'spec_helper'

describe CustomersController do
  render_views

  describe "Filters" do
    context "When the logged user is an admin" do
      before :each do
        sign_in_admin
      end

      it "should be able to view a single customer" do
        customer = Customer.make(:company => @logged_user.company)
        get :show, :id => customer.id
        response.should be_success
      end

      it "should be able to create a new customer" do
        get :new
        response.should be_success
      end

      it "should be able to edit a customer" do
        customer = Customer.make(:company => @logged_user.company)
        get :edit, :id => customer.id
        response.should be_success
      end

      it "should be able to delete a customer" do
        customer = Customer.make(:company => @logged_user.company)
        delete :destroy, :id => customer.id
        response.should redirect_to root_path
      end
    end

    context "When the logged user is not and admin" do
      before :each do
        sign_in_normal_user(seen_welcome: 1)
      end

      context "When trying to read customers and the user is not authorized to do so" do
        before :each do
          @logged_user.update_attributes(:read_clients => false)
        end
      end

      context "When trying to read customers and the user is authorized to do so" do
        before :each do
          @logged_user.update_attributes(:read_clients => true)
        end
      end

      context "When trying to create a new customer and the user is not authorized to do so" do
        before :each do
          @logged_user.update_attributes(:create_clients => false)
        end

        it "should redirect to the root_path" do
          get :new
          response.should redirect_to root_path
        end

        it "should indicated the user that access is denied" do
          get :new
          flash[:error].should match 'Access denied'
        end
      end

      context "When trying to create a new customer and the user is authorized to do so" do
        before :each do
          @logged_user.update_attributes(:create_clients => true)
        end

        it "should allow the access" do
          get :new
          response.should be_success
        end
      end

      context "When trying to edit a customer and the user is not authorized to do so" do
        before :each do
          @logged_user.update_attributes(:edit_clients => false)
          @customer = Customer.make(:company => @logged_user.company)
        end

        it "should redirect to the root_path" do
          get :edit, :id => @customer.id
          response.should redirect_to root_path
        end

        it "should indicated the user that access is denied" do
          get :edit, :id => @customer.id
          flash[:error].should match 'Access denied'
        end
      end

      context "When trying to edit a customer and the user is authorized to do so" do
        before :each do
          @logged_user.update_attributes(:edit_clients => true)
          @customer = Customer.make(:company => @logged_user.company)
        end

        it "should allow the access" do
          get :edit, :id => @customer.id
          response.should be_success
        end
      end
    end
  end

  describe "GET 'show'" do
    context "When the logged user is authorized" do
      before :each do
        sign_in_admin
        @logged_user.stub!(:read_clients?).and_return(true)
        @some_customer = Customer.make(:company => @logged_user.company)
      end

      it "should be succesful" do
        get :show, :id => @some_customer.id  
        response.should be_success
      end

      it "should render the right template" do
        get :show, :id => @some_customer.id
        response.should render_template :show
      end
    end
  end

  describe "GET 'new'" do
    context "When the logged user is authorized" do
      before :each do
        sign_in_admin
        @logged_user.stub!(:create_clients?).and_return(true)
      end

      it "should be successful" do
        get :new
        response.should be_success
      end

      it "should render the right template" do
        get :new
        response.should render_template :new
      end
    end
  end

  describe "POST 'create'" do
    context "When the logged user is authorized" do
      before :each do
        sign_in_admin
        @logged_user.stub!(:create_clients?).and_return(true)
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
          flash[:success].should match 'Customer was successfully created.'
        end

        it "should redirect to the root" do
          post :create, :customer => @valid_attributes
          response.should redirect_to root_path
        end
      end

      context "When using invalid attributes" do
        before :each do
          company_id = @logged_user.company_id
          @invalid_attributes = { :name => '', :company_id => company_id }
        end

        it "should render the 'new' template" do
          post :create, :customer => @invalid_attributes
          response.should render_template :new
        end
      end
    end
  end

  describe "GET 'edit'" do
    context "When the logged user is authorized" do
      before :each do
        sign_in_admin
        @logged_user.stub!(:edit_clients?).and_return(true)
        @some_customer = Customer.make(:company => @logged_user.company)
      end

      it "should be successful" do
        get :edit, :id => @some_customer
        response.should be_success
      end

      it "should render the right template" do
        get :edit, :id => @some_customer
        response.should render_template :edit
      end
    end    
  end

  describe "PUT 'update'" do
    context "When the logged user is authorized" do
      before :each do
        sign_in_admin
        @logged_user.stub!(:edit_clients?).and_return(true)
        @some_customer = Customer.make(:company => @logged_user.company)
      end

      context "When using valid attributes" do
        before :each do
          @valid_attributes = { :name => 'new_name' }
        end

        it "shoud update the customer record successfully" do
          put :update, :id => @some_customer, :customer => @valid_attributes
          @some_customer.reload
          @some_customer.name.should match @valid_attributes[:name]
        end

        it "should redirect to the 'edit' action" do
          put :update, :id => @some_customer, :customer => @valid_attributes
          response.should redirect_to "/customers/#{@some_customer.id}/edit"
        end

        it "should tell the user that the customer was updated" do
          put :update, :id => @some_customer, :customer => @valid_attributes
          flash[:success].should match 'Customer was successfully updated.' 
        end
      end
      
      context "When using invalid attributes" do
        it "should render the 'edit' view" do
          put :update, :id => @some_customer, :customer => { :name => '' }
          response.should render_template :edit
        end
      end
    end
  end

  describe "DELETE 'destroy'" do
    context "When the logged user is authorized" do
      before :each do
        sign_in_admin
        @logged_user.stub!(:edit_clients?).and_return(true)
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
          response.should redirect_to root_path
        end

        it "should tell the user that the customer was deleted" do
          delete :destroy, :id => @some_customer
          flash[:success].should match 'Customer was successfully deleted.'
        end
      end
      
      context "When the customer have projects" do
        before :each do
          @some_customer.projects << Project.make
        end

        it "should not be able to delete the instance" do
          expect {
            delete :destroy, :id => @some_customer
          }.to_not change { Customer.count }.by(-1)
        end

        it "should tell the user that it can't delete the customer" do
          delete :destroy, :id => @some_customer
          msg = "Please delete all projects for #{@some_customer.name} before deleting it."
          flash[:error].should match msg
        end

        it "should redirect to the root" do
          delete :destroy, :id => @some_customer
          response.should redirect_to root_path
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
          }.to_not change { Customer.count }.by(-1)
        end

        it "should tell the user that it can't delete the customer" do
          delete :destroy, :id => @some_customer
          flash[:error].should match "You can't delete your own company."
        end

        it "should redirect to the root" do
          delete :destroy, :id => @some_customer
          response.should redirect_to root_path
        end
      end
    end
  end

  describe "POST 'search'" do
    before :each do
      sign_in_normal_user

      @customer_one   = Customer.make(:name => 'Juan', :company => @logged_user.company)
      @customer_two   = Customer.make(:name => 'Omar', :company => @logged_user.company)
    end

    it "should fetch the right customers based on the provided search criteria" do
      get :search, :term => @customer_one.name
      response.body.should match @customer_one.name
      get :search, :term => @customer_two.name
      response.body.should match @customer_two.name
    end
  end
end
