require 'spec_helper'

describe CustomersController do
  render_views

  describe "Filters" do
    context "When the logged user is an admin" do
      before :each do
        sign_in_admin
      end

      it "should be able to list all customers" do
        get :index
        response.should be_success
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
        response.should redirect_to customers_path
      end
    end

    context "When the logged user is not and admin" do
      before :each do
        sign_in_normal_user
      end

      context "When trying to read customers and the user is not authorized to do so" do
        before :each do
          @logged_user.update_attributes(:read_clients => false)
        end

        it "should redirect to the root_path" do
          get :index
          response.should redirect_to root_path
        end

        it "should indicated the user that access is denied" do
          get :index
          flash['notice'].should match 'Access denied'
        end
      end

      context "When trying to read customers and the user is authorized to do so" do
        before :each do
          @logged_user.update_attributes(:read_clients => true)
        end

        it "should allow the access" do
          get :index
          response.should be_success
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
          flash['notice'].should match 'Access denied'
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
          flash['notice'].should match 'Access denied'
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
