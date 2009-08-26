require 'test_helper'

class CustomAttributeChoiceTest < ActiveSupport::TestCase
  def setup
    @choice = CustomAttributeChoice.new
  end

  test "should belong to custom attribute" do
    assert @choice.respond_to?(:custom_attribute)
  end
end
