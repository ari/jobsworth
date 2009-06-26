require 'test_helper'

class PreferenceTest < ActiveSupport::TestCase
  should_belong_to :preferencable
end
