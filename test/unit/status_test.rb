require 'test_helper'

class StatusTest < ActiveSupport::TestCase
  should_belong_to :company
  should_validate_presence_of :company
end
