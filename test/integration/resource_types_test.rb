require 'test_helper'

class ResourceTypesTest < ActionController::IntegrationTest
  context "a logged in resource user" do
    setup do
      @user = login
      @user.use_resources = true
      @user.admin = true
      @user.save!

      visit "/resource_types"
    end

    should "be able to create a new resource type" do
      click_link "New resource type"

      fill_in "Name", :with => "new resource type"
      click_button "Create"

      assert_equal "new resource type", ResourceType.last(:order => "id asc").name
    end

    context "with an existing resource type" do
      # N.B I am putting in a lot of tests here because I think this
      # may get merged with task properties at some point and want to make
      # sure we don't break anything in the merge.
      setup do
        @type = ResourceType.make(:company => @user.company)
        @type.resource_type_attributes.build(:name => "attr1")
        @type.resource_type_attributes.build(:name => "attr2")
        @type.save!

        attr_id = @type.resource_type_attributes.first.id
        @prefix = "resource_type_type_attributes_#{ attr_id }"

        visit "/resource_types"
      end

      context "editing a resource type" do
        setup do
          click_link "Edit"
        end

        should "be able to edit the name" do
          fill_in "Name", :with => "a new name"
          click_button "Save"
          assert_equal "a new name", @type.reload.name
        end

        should "be able to edit attribute name" do
          fill_in "#{ @prefix }_name", :with => "new name 1"
          click_button "Save"
          attr = @type.resource_type_attributes.first
          assert_equal "new name 1", attr.name
        end

        should "be able to set attribute is mandatory" do
          check "#{ @prefix }_is_mandatory"
          click_button "Save"
          attr = @type.resource_type_attributes.first
          assert attr.is_mandatory?
        end

        should "be able to set attribute is password" do
          check "#{ @prefix }_is_password"
          click_button "Save"
          attr = @type.resource_type_attributes.first
          assert attr.is_password?
        end

        should "be able to set attribute allows multiple" do
          check "#{ @prefix }_allows_multiple"
          click_button "Save"
          attr = @type.resource_type_attributes.first
          assert attr.allows_multiple?
        end

        should "be able to set validation regex" do
          fill_in "#{ @prefix }_validation_regex", :with => "\d"
          click_button "Save"
          attr = @type.resource_type_attributes.first
          assert_equal "\d", attr.validation_regex
        end

        should "be able to set default field length" do
          fill_in "#{ @prefix }_default_field_length", :with => 10
          click_button "Save"
          attr = @type.resource_type_attributes.first
          assert_equal 10, attr.default_field_length
        end
      end

      should "be able to delete that type" do
        click_link "Delete"
        assert_nil ResourceType.find_by_id(@type.id)
      end
    end
  end
end
