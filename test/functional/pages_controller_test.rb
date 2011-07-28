require "test_helper"

class PagesControllerTest < ActionController::TestCase

  signed_in_admin_context do
    should "be able to get new" do
      get :new
      assert_response :success
    end

    should "be able to post create" do
      put :create, :page => Page.make.attributes
      assert_redirected_to assigns("page")
    end

    should "be able to post target_list" do
      post :target_list, :term => @user.name
      assert_response :success
    end

    context "with an existing page" do
      setup do
        @page = Page.make(:user => @user, :company => @user.company)
      end

      should "be able to get edit" do
        get :edit, :id => @page.id
        assert_response :success
      end

      should "be able to put update" do
        put :update, :id => @page.id, :page => { :name => "new name" }
        assert_redirected_to @page
        assert_equal "new name", @page.reload.name
      end

      should "be able to update only page body, without changing page name" do
        put :update, :id=> @page.id, :page=>{ :body=>"new body"}
        assert_redirected_to @page
        assert_equal "new body", @page.reload.body
      end

      should "be able to delete a page" do
        delete :destroy, :id => @page.id
        assert_redirected_to "/tasks"
        assert_nil Page.find_by_id(@page.id)
      end
    end
  end
end
