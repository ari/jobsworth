require "test_helper"

class PreferenceTest < ActiveSupport::TestCase
  should belong_to(:preferencable)
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
# Indexes
#
#  index_preferences_on_preferencable_id_and_preferencable_type  (preferencable_id,preferencable_type)
#

