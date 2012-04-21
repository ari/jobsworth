require "test_helper"

class CustomAttributeChoiceTest < ActiveSupport::TestCase
  def setup
    @choice = CustomAttributeChoice.new
  end

  test "should belong to custom attribute" do
    assert @choice.respond_to?(:custom_attribute)
  end
end






# == Schema Information
#
# Table name: custom_attribute_choices
#
#  id                  :integer(4)      not null, primary key
#  custom_attribute_id :integer(4)
#  value               :string(255)
#  position            :integer(4)
#  created_at          :datetime
#  updated_at          :datetime
#  color               :string(255)
#
# Indexes
#
#  index_custom_attribute_choices_on_custom_attribute_id  (custom_attribute_id)
#

