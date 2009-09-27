require 'test_helper'

class InstallControllerTest < ActionController::TestCase

  context "an install with any companies" do
    setup do
      company = Company.make
    end

    should "not redirected away" do
      get :index
      assert_redirected_to "/tasks/list"
    end
  end

  context "an install with no companies" do
    setup do
      Company.destroy_all
    end

    should "get index" do
      get :index
      assert_response :success
    end

    context "posting required information" do
      setup do
        post(:create, 
             :user => { :name => "test", :password => "password", 
               :time_zone => "Australia/Sydney" },
             :company => { :name => "testco" },
             :project => { :name => "project 1" })
      end

      should "create company" do
        assert_equal 1, Company.count
        assert_equal "testco", Company.first.name
      end

      should "create user" do
        assert_equal 1, User.count
        assert_equal "test", User.first.name
      end

      should "create project" do
        assert_equal 1, Project.count
        assert_equal "project 1", Project.first.name
      end

      should "login and redirect to new task" do
        assert @response.redirected_to.index("/tasks/new")
      end
    end
  end
end
