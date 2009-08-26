require 'test_helper'

class KeywordTest < ActiveSupport::TestCase
  should_belong_to :task_filter
  should_belong_to :company

  should_validate_presence_of :task_filter
  should_validate_presence_of :company
end
