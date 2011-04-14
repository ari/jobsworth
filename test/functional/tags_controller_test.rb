require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  signed_in_admin_context do
    setup do
      @tags = []
      3.times do 
        @tags << Tag.make(:company => @user.company)
      end
    end

    should "be able to render tag list" do
      get :index
      assert_response :success
      assert_equal @tags, assigns("tags")
    end

    should "be able to render edit" do
      get :edit, :id => @tags.first.id
      assert_response :success
    end

    should "be able to update a tag" do
      tag = @tags.first

      put :update, :id =>  tag.id, :tag => { :name => "a new name" }
      assert_redirected_to "/tags"
      assert_equal "a new name", tag.reload.name
    end

    should "be able to delete a tag" do
      tag = @tags.first

      delete :destroy, :id => tag.id
      assert_redirected_to "/tags"
      assert_nil Tag.find_by_id(tag.id)
    end
  end

end
