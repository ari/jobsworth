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
  end
end
