require 'test_helper'

class PreferenceTest < ActiveSupport::TestCase
  should_belong_to :preferencable
end

# == Schema Information
#
# Table name: preferences
#
#  id                 :integer(4)      not null, primary key
#  preferencable_id   :integer(4)
#  preferencable_type :string(255)
#  key                :string(255)
#  value              :text
#  created_at         :datetime
#  updated_at         :datetime
#

