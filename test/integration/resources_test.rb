require 'test_helper'

class ResourcesTest < ActionController::IntegrationTest
  context "a logged in resource user with some resource types" do
    setup do
      @user = login
      @user.use_resources = true
      @user.admin = true
      @user.save!

      @type = ResourceType.make(:company => @user.company)
      @attr1 = @type.resource_type_attributes.build(:name => "attr1")
      @attr2 = @type.resource_type_attributes.build(:name => "attr2")
      @type.save!

      visit "/"
    end

    context "and an existing resource" do
      setup do
        @resource = Resource.make(:company => @user.company,
                                  :customer => @user.customer,
                                  :resource_type => @type)
        @resource.resource_attributes.build(:resource_type_attribute => @attr1,
                                            :value => "any old value 1")
        @resource.resource_attributes.build(:resource_type_attribute => @attr2,
                                            :value => "any old value 2")
        @resource.save!

      end

      context "editing a resource" do
        setup do
          visit "/resources/edit/#{@resource.id}"
        end

        should "be able to edit name" do
          fill_in "Name", :with => "a new name"
          click_button "Save"
          assert_equal "a new name", @resource.reload.name
        end

        should "be able to set attribute values" do
          fill_in @attr1.name, :with => "val1"
          fill_in @attr2.name, :with => "val2"
          click_button "Save"

          @resource.reload
          val1 = @resource.resource_attributes.detect { |ra| ra.resource_type_attribute == @attr1 }
          val2 = @resource.resource_attributes.detect { |ra| ra.resource_type_attribute == @attr2 }
          assert_equal "val1", val1.value
          assert_equal "val2", val2.value
        end

        should "be able to edit notes" do
          fill_in "Notes", :with => "some notes"
          click_button "Save"
          assert_equal "some notes", @resource.reload.notes
        end

        should "be able to delete the resource" do
          click_link "Delete"
          assert_nil Resource.find_by_id(@resource.id)
        end
      end
    end
  end
end
